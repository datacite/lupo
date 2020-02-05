module Indexable
  extend ActiveSupport::Concern

  require 'aws-sdk-sqs'

  included do
    after_commit on: [:create, :update] do
      # use index_document instead of update_document to also update virtual attributes
      IndexJob.perform_later(self)
      if self.class.name == "Doi"
        update_column(:indexed, Time.zone.now)
        send_import_message(self.to_jsonapi) if aasm_state == "findable" && !Rails.env.test? && !%w(crossref medra kisti jalc op).include?(client.symbol.downcase.split(".").first)
      end
    end

    after_touch do
      # use index_document instead of update_document to also update virtual attributes
      IndexBackgroundJob.perform_later(self)
    end

    before_destroy do
      begin
        __elasticsearch__.delete_document
        # send_delete_message(self.to_jsonapi) if self.class.name == "Doi" && !Rails.env.test?
      rescue Elasticsearch::Transport::Transport::Errors::NotFound
        nil
      end
    end

    def send_delete_message(data)
      send_message(data, shoryuken_class: "DoiDeleteWorker")
    end

    def send_import_message(data)
      send_message(data, shoryuken_class: "DoiImportWorker")
    end

    # shoryuken_class is needed for the consumer to process the message
    # we use the AWS SQS client directly as there is no consumer in this app
    def send_message(body, options={})
      sqs = Aws::SQS::Client.new
      queue_url = sqs.get_queue_url(queue_name: "#{Rails.env}_doi").queue_url
      options[:shoryuken_class] ||= "DoiImportWorker"

      options = {
        queue_url: queue_url,
        message_attributes: {
          'shoryuken_class' => {
            string_value: options[:shoryuken_class],
            data_type: 'String'
          },
        },
        message_body: body.to_json,
      }

      sqs.send_message(options)
    end
  end

  module ClassMethods
    # return results for one or more ids
    def find_by_id(ids, options={})
      ids = ids.split(",") if ids.is_a?(String)
      options[:page] ||= {}
      options[:page][:number] ||= 1
      options[:page][:size] ||= 2000
      options[:sort] ||= { created: { order: "asc" }}

      __elasticsearch__.search({
        from: (options.dig(:page, :number) - 1) * options.dig(:page, :size),
        size: options.dig(:page, :size),
        sort: [options[:sort]],
        track_total_hits: true,
        query: {
          terms: {
            symbol: ids.map(&:upcase)
          }
        },
        aggregations: query_aggregations
      })
    end

    def find_by_id_list(ids, options={})
      options[:sort] ||= { "_doc" => { order: 'asc' }}

      __elasticsearch__.search({
        from: options[:page].present? ? (options.dig(:page, :number) - 1) * options.dig(:page, :size) : 0,
        size: options[:size] || 25,
        sort: [options[:sort]],
        track_total_hits: true,
        query: {
          terms: {
            id: ids.split(",")
          }
        },
        aggregations: query_aggregations
      })
    end

    def get_aggregations_hash(options={})
      aggregations = options[:aggregations] || ""
      return send(:query_aggregations) if aggregations.blank?
      aggs = {}
      aggregations.split(",").each do |agg|
        agg = :query_aggregations if agg.blank? || !respond_to?(agg)
        aggs.merge! send(agg)
      end
      aggs
    end

    def query(query, options={})
      # support scroll api
      # map function is small performance hit
      if options[:scroll_id].present? && options.dig(:page, :scroll)
        begin
          response = __elasticsearch__.client.scroll(body: 
            { scroll_id: options[:scroll_id],
              scroll: options.dig(:page, :scroll)
            })
          return Hashie::Mash.new({
              total: response.dig("hits", "total", "value"),
              results: response.dig("hits", "hits").map { |r| r["_source"] },
              scroll_id: response["_scroll_id"]
            })
        # handle expired scroll_id (Elasticsearch returns this error)
        rescue Elasticsearch::Transport::Transport::Errors::NotFound
          return Hashie::Mash.new({
            total: 0,
            results: [],
            scroll_id: nil
          })
        end
      end

      if options[:totals_agg] == "provider"
        aggregations = provider_aggregations
      elsif options[:totals_agg] == "client"
        aggregations = client_aggregations
      elsif options[:totals_agg] == "prefix"
        aggregations = prefix_aggregations
      else
        aggregations = get_aggregations_hash(options)
      end

      options[:page] ||= {}
      options[:page][:number] ||= 1
      options[:page][:size] ||= 25

      # Cursor nav use the search after, this should always be an array of values that match the sort.
      if options.dig(:page, :cursor)
        from = 0

        # make sure we have a valid cursor
        search_after = options.dig(:page, :cursor).presence || [1, "1"]

        if self.name == "Doi"
          sort = [{ created: "asc", uid: "asc" }]
        elsif self.name == "Event"
          sort = [{ created_at: "asc", uuid: "asc" }]
        elsif self.name == "Activity"
          sort = [{ created: "asc", request_uuid: "asc" }]
        elsif %w(Client Provider).include?(self.name)
          sort = [{ created: "asc", uid: "asc" }]
        elsif self.name == "Researcher"
          sort = [{ created_at: "asc", uid: "asc" }]
        else
          sort = [{ created: "asc" }]
        end
      else
        from = ((options.dig(:page, :number) || 1) - 1) * (options.dig(:page, :size) || 25)
        search_after = nil
        sort = options[:sort]
      end

      # make sure field name uses underscore
      # escape forward slashes in query
      if query.present?
        query = query.gsub(/publicationYear/, "publication_year")
        query = query.gsub(/relatedIdentifiers/, "related_identifiers")
        query = query.gsub(/rightsList/, "rights_list")
        query = query.gsub(/fundingReferences/, "funding_references")
        query = query.gsub(/geoLocations/, "geo_locations")
        query = query.gsub(/landingPage/, "landing_page")
        query = query.gsub(/contentUrl/, "content_url")
        query = query.gsub("/", '\/')
      end

      must = []
      must << { query_string: { query: query, fields: query_fields }} if query.present?
      must << { term: { "types.resourceTypeGeneral": options[:resource_type_id].underscore.camelize }} if options[:resource_type_id].present?
      must << { terms: { provider_id: options[:provider_id].split(",") }} if options[:provider_id].present?
      must << { terms: { client_id: options[:client_id].to_s.split(",") }} if options[:client_id].present?
      must << { terms: { prefix: options[:prefix].to_s.split(",") }} if options[:prefix].present?
      must << { term: { uid: options[:uid] }} if options[:uid].present?
      must << { range: { created: { gte: "#{options[:created].split(",").min}||/y", lte: "#{options[:created].split(",").max}||/y", format: "yyyy" }}} if options[:created].present?
      must << { term: { schema_version: "http://datacite.org/schema/kernel-#{options[:schema_version]}" }} if options[:schema_version].present?
      must << { terms: { "subjects.subject": options[:subject].split(",") }} if options[:subject].present?
      must << { term: { source: options[:source] }} if options[:source].present?
      must << { term: { "landing_page.status": options[:link_check_status] }} if options[:link_check_status].present?
      must << { exists: { field: "landing_page.checked" }} if options[:link_checked].present?
      must << { term: { "landing_page.hasSchemaOrg": options[:link_check_has_schema_org] }} if options[:link_check_has_schema_org].present?
      must << { term: { "landing_page.bodyHasPid": options[:link_check_body_has_pid] }} if options[:link_check_body_has_pid].present?
      must << { exists: { field: "landing_page.schemaOrgId" }} if options[:link_check_found_schema_org_id].present?
      must << { exists: { field: "landing_page.dcIdentifier" }} if options[:link_check_found_dc_identifier].present?
      must << { exists: { field: "landing_page.citationDoi" }} if options[:link_check_found_citation_doi].present?
      must << { range: { "landing_page.redirectCount": { "gte": options[:link_check_redirect_count_gte] } } } if options[:link_check_redirect_count_gte].present?

      must_not = []

      # filters for some classes
      if self.name == "Provider"
        must << { range: { created: { gte: "#{options[:year].split(",").min}||/y", lte: "#{options[:year].split(",").max}||/y", format: "yyyy" }}} if options[:year].present?
        must << { term: { region: options[:region].upcase }} if options[:region].present?
        must << { term: { "consortium_id.raw" => options[:consortium_id] }} if options[:consortium_id].present?
        must << { term: { member_type: options[:member_type] }} if options[:member_type].present?
        must << { term: { organization_type: options[:organization_type] }} if options[:organization_type].present?
        must << { term: { non_profit_status: options[:non_profit_status] }} if options[:non_profit_status].present?
        must << { term: { focus_area: options[:focus_area] }} if options[:focus_area].present?

        must_not << { exists: { field: "deleted_at" }} unless options[:include_deleted]
        if options[:exclude_registration_agencies]
          must_not << { terms: { role_name: ["ROLE_ADMIN", "ROLE_REGISTRATION_AGENCY", "ROLE_CONSORTIUM_ORGANIZATION"] }}
        else
          must_not << { term: { role_name: "ROLE_ADMIN" }}
        end
      elsif self.name == "Client"
        must << { range: { created: { gte: "#{options[:year].split(",").min}||/y", lte: "#{options[:year].split(",").max}||/y", format: "yyyy" }}} if options[:year].present?
        must << { terms: { "software.raw" => options[:software].split(",") }} if options[:software].present?
        must << { terms: { certificate: options[:certificate].split(",") }} if options[:certificate].present?
        must << { terms: { repository_type: options[:repository_type].split(",") }} if options[:repository_type].present?
        must << { term: { consortium_id: options[:consortium_id] }} if options[:consortium_id].present?
        must << { term: { re3data_id: options[:re3data_id].gsub("/", '\/').upcase }} if options[:re3data_id].present?
        must << { term: { opendoar_id: options[:opendoar_id] }} if options[:opendoar_id].present?
        must << { term: { client_type: options[:client_type] }} if options[:client_type].present?
        must_not << { exists: { field: "deleted_at" }} unless options[:include_deleted]
        must_not << { terms: { provider_id: ["crossref", "medra", "op"] }} if options[:exclude_registration_agencies]
      elsif self.name == "Doi"
        must << { terms: { aasm_state: options[:state].to_s.split(",") }} if options[:state].present?
        must << { range: { registered: { gte: "#{options[:registered].split(",").min}||/y", lte: "#{options[:registered].split(",").max}||/y", format: "yyyy" }}} if options[:registered].present?
        must << { term: { "creators.nameIdentifiers.nameIdentifier" => "https://orcid.org/#{options[:user_id]}" }} if options[:user_id].present?
        must << { term: { "creators.affiliation.affiliationIdentifier" => URI.decode(options[:affiliation_id]) }} if options[:affiliation_id].present?
        must << { term: { consortium_id: options[:consortium_id] }} if options[:consortium_id].present?
        must << { term: { "client.re3data_id" => options[:re3data_id].gsub("/", '\/').upcase }} if options[:re3data_id].present?
        must << { term: { "client.opendoar_id" => options[:opendoar_id] }} if options[:opendoar_id].present?
        must << { terms: { "client.certificate" => options[:certificate].split(",") }} if options[:certificate].present?
        must_not << { terms: { provider_id: ["crossref", "medra", "op"] }} if options[:exclude_registration_agencies]
      elsif self.name == "Event"
        must << { term: { subj_id: URI.decode(options[:subj_id]) }} if options[:subj_id].present?
        must << { term: { obj_id: URI.decode(options[:obj_id]) }} if options[:obj_id].present?
        must << { term: { citation_type: options[:citation_type] }} if options[:citation_type].present?
        must << { term: { year_month: options[:year_month] }} if options[:year_month].present?
        must << { range: { "subj.datePublished" => { gte: "#{options[:publication_year].split("-").min}||/y", lte: "#{options[:publication_year].split("-").max}||/y", format: "yyyy" }}} if options[:publication_year].present?
        must << { range: { occurred_at: { gte: "#{options[:occurred_at].split("-").min}||/y", lte: "#{options[:occurred_at].split("-").max}||/y", format: "yyyy" }}} if options[:occurred_at].present?
        must << { terms: { prefix: options[:prefix].split(",") }} if options[:prefix].present?
        must << { terms: { doi: options[:doi].downcase.split(",") }} if options[:doi].present?
        must << { terms: { orcid: options[:orcid].split(",") }} if options[:orcid].present?
        must << { terms: { isni: options[:isni].split(",") }} if options[:isni].present?
        must << { terms: { subtype: options[:subtype].split(",") }} if options[:subtype].present?
        must << { terms: { source_id: options[:source_id].split(",") }} if options[:source_id].present?
        must << { terms: { relation_type_id: options[:relation_type_id].split(",") }} if options[:relation_type_id].present?
        must << { terms: { registrant_id: options[:registrant_id].split(",") }} if options[:registrant_id].present?
        must << { terms: { registrant_id: options[:provider_id].split(",") }} if options[:provider_id].present?
        must << { terms: { issn: options[:issn].split(",") }} if options[:issn].present?
      end

      # ES query can be optionally defined in different ways
      # So here we build it differently based upon options
      # This is mostly useful when trying to wrap it in a function_score query
      es_query = {}

      # The main bool query with filters
      bool_query = {
        must: must,
        must_not: must_not
      }

      # Function score is used to provide varying score to return different values
      # We use the bool query above as our principle query
      # Then apply additional function scoring as appropriate
      # Note this can be performance intensive.
      function_score = {
        query: {
          bool: bool_query
        },
        random_score: {
          "seed": Rails.env.test? ? "random_1234" : "random_#{rand(1...100000)}"
        }
      }

      if options[:random].present?
        es_query['function_score'] = function_score
        # Don't do any sorting for random results
        sort = nil
      else
        es_query['bool'] = bool_query
      end

      # Sample grouping is optional included aggregation
      if options[:sample_group].present?
        aggregations[:samples] = {
          terms: {
            field: options[:sample_group],
            size: 10000
          },
          aggs: {
            "samples_hits": {
              top_hits: {
                size: options[:sample_size].present? ? options[:sample_size] : 1
              }
            }
          }
        }
      end

      # Collap results list by unique citations
      unique = options[:unique].blank? ? nil : {
        field: "citation_id",
        inner_hits: {
          name: "first_unique_event",
          size: 1
        },
        "max_concurrent_group_searches": 1
      }

      # three options for going through results are scroll, cursor and pagination
      # the default is pagination
      # scroll is triggered by the page[scroll] query parameter
      # cursor is triggered by the page[cursor] query parameter

      # can't use search wrapper function for scroll api
      # map function for scroll is small performance hit
      if options.dig(:page, :scroll).present?
        response = __elasticsearch__.client.search(
          index: self.index_name,
          scroll: options.dig(:page, :scroll),
          body: { 
            size: options.dig(:page, :size),
            sort: sort,
            query: es_query,
            collapse: unique,
            aggregations: aggregations,
            track_total_hits: true
          }.compact)
        Hashie::Mash.new({
          total: response.dig("hits", "total", "value"),
          results: response.dig("hits", "hits").map { |r| r["_source"] },
          scroll_id: response["_scroll_id"]
        })
      elsif options.dig(:page, :cursor).present?
        __elasticsearch__.search({
          size: options.dig(:page, :size),
          search_after: search_after,
          sort: sort,
          query: es_query,
          collapse: unique,
          aggregations: aggregations,
          track_total_hits: true
        }.compact)
      else
        __elasticsearch__.search({
          size: options.dig(:page, :size),
          from: from,
          sort: sort,
          query: es_query,
          collapse: unique,
          aggregations: aggregations,
          track_total_hits: true
        }.compact)
      end
    end

    def recreate_index(options={})
      client     = self.gateway.client
      index_name = self.index_name

      client.indices.delete index: index_name rescue nil if options[:force]
      client.indices.create index: index_name, body: { settings:  {"index.requests.cache.enable": true }}
    end

    def count
      Elasticsearch::Model.client.count(index: index_name)['count']
    end

    # Aliasing
    #
    # We are using two indexes, where one is active (used for API calls) via aliasing and the other one
    # is inactive. All index configuration changes and bulk importing from the database
    # happen in the inactive index.
    #
    # For initial setup run "start_aliases" to preserve existing index, or
    # "create_index" to start from scratch.
    #
    # Run "upgrade_index" whenever there are changes in the mappings or settings.
    # Follow this by "import" to fill the new index, the usen "switch_index" to
    # alias the new index and remove alias from current index.
    #
    # TODO: automatically switch aliases when "import" is done. Not easy, as "import"
    # runs as background jobs.

    # convert existing index to alias. Has to be done only once
    def start_aliases
      alias_name = self.index_name
      index_name = self.index_name + "_v1"
      alternate_index_name = self.index_name + "_v2"

      client = Elasticsearch::Model.client

      if client.indices.exists_alias?(name: alias_name)
        return "Index #{alias_name} is already an alias."
      end

      self.__elasticsearch__.create_index!(index: index_name) unless self.__elasticsearch__.index_exists?(index: index_name)
      self.__elasticsearch__.create_index!(index: alternate_index_name) unless self.__elasticsearch__.index_exists?(index: alternate_index_name)

      # copy old index to first of the new indexes, delete the old index, and alias the old index
      client.reindex(body: { source: { index: alias_name }, dest: { index: index_name } }, timeout: "10m", wait_for_completion: false)

      "Created indexes #{index_name} (active) and #{alternate_index_name}."
      "Started reindexing in #{index_name}."
    end

    # track reindexing via the tasks API
    def monitor_reindex
      client = Elasticsearch::Model.client
      tasks = client.tasks.list(actions: "*reindex")
      tasks.fetch("nodes", {}).inspect
    end

    # convert existing index to alias. Has to be done only once
    def finish_aliases
      alias_name = self.index_name
      index_name = self.index_name + "_v1"

      client = Elasticsearch::Model.client

      if client.indices.exists_alias?(name: alias_name)
        return "Index #{alias_name} is already an alias."
      end

      self.__elasticsearch__.delete_index!(index: alias_name) if self.__elasticsearch__.index_exists?(index: alias_name)
      client.indices.put_alias index: index_name, name: alias_name

      "Converted index #{alias_name} into an alias."
    end

    # create both indexes used for aliasing
    def create_index
      alias_name = self.index_name
      index_name = self.index_name + "_v1"
      alternate_index_name = self.index_name + "_v2"

      self.__elasticsearch__.create_index!(index: index_name) unless self.__elasticsearch__.index_exists?(index: index_name)
      self.__elasticsearch__.create_index!(index: alternate_index_name) unless self.__elasticsearch__.index_exists?(index: alternate_index_name)
      
      # index_name is the active index
      client = Elasticsearch::Model.client
      client.indices.put_alias index: index_name, name: alias_name unless client.indices.exists_alias?(name: alias_name)
      
      "Created indexes #{index_name} (active) and #{alternate_index_name}."
    end

    # delete both indexes used for aliasing
    def delete_index
      alias_name = self.index_name
      index_name = self.index_name + "_v1"
      alternate_index_name = self.index_name + "_v2"

      client = Elasticsearch::Model.client
      client.indices.delete_alias index: index_name, name: alias_name if client.indices.exists_alias?(name: alias_name, index: [index_name])
      client.indices.delete_alias index: alternate_index_name, name: alias_name if client.indices.exists_alias?(name: alias_name, index: [alternate_index_name])

      self.__elasticsearch__.delete_index!(index: index_name) if self.__elasticsearch__.index_exists?(index: index_name)
      self.__elasticsearch__.delete_index!(index: alternate_index_name) if self.__elasticsearch__.index_exists?(index: alternate_index_name)

      "Deleted indexes #{index_name} and #{alternate_index_name}."
    end

    # delete and create inactive index to use current mappings
    # Needs to run every time we change the mappings
    def upgrade_index
      inactive_index ||= self.inactive_index
      
      self.__elasticsearch__.delete_index!(index: inactive_index) if self.__elasticsearch__.index_exists?(index: inactive_index)

      if self.__elasticsearch__.index_exists?(index: inactive_index)
        "Error: inactive index #{inactive_index} could not be upgraded."
      else
        self.__elasticsearch__.create_index!(index: inactive_index)
        "Upgraded inactive index #{inactive_index}."
      end
    end

    # show stats for both indexes
    def index_stats(options={})
      active_index = self.active_index
      inactive_index = self.inactive_index

      client = Elasticsearch::Model.client
      stats = client.indices.stats index: [active_index, inactive_index], docs: true
      active_index_count = stats.dig("indices", active_index, "primaries", "docs", "count")
      inactive_index_count = stats.dig("indices", inactive_index, "primaries", "docs", "count")
      database_count = self.all.count

      message = "Active index #{active_index} has #{active_index_count} documents, " \
        "inactive index #{inactive_index} has #{inactive_index_count} documents, " \
        "database has #{database_count} documents."
      return message
    end

    # switch between the two indexes, i.e. the index that is aliased
    def switch_index(options={})
      alias_name = self.index_name
      index_name = self.index_name + "_v1"
      alternate_index_name = self.index_name + "_v2"

      client = Elasticsearch::Model.client

      if client.indices.exists_alias?(name: alias_name, index: [index_name])
        client.indices.update_aliases body: {
          actions: [
            { remove: { index: index_name, alias: alias_name } },
            { add:    { index: alternate_index_name, alias: alias_name } }
          ]
        }

        "Switched active index to #{alternate_index_name}."
      elsif client.indices.exists_alias?(name: alias_name, index: [alternate_index_name])
        client.indices.update_aliases body: {
          actions: [
            { remove: { index: alternate_index_name, alias: alias_name } },
            { add:    { index: index_name, alias: alias_name } }
          ]
        }
        
        "Switched active index to #{index_name}."
      end
    end

    # Return the active index, i.e. the index that is aliased
    def active_index
      alias_name = self.index_name
      client = Elasticsearch::Model.client
      client.indices.get_alias(name: alias_name).keys.first
    end

    # Return the inactive index, i.e. the index that is not aliased
    def inactive_index
      alias_name = self.index_name
      index_name = self.index_name + "_v1"
      alternate_index_name = self.index_name + "_v2"

      client = Elasticsearch::Model.client
      active_index = client.indices.get_alias(name: alias_name).keys.first
      active_index.end_with?("v1") ? alternate_index_name : index_name
    end
  end
end
