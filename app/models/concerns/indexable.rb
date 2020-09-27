module Indexable
  extend ActiveSupport::Concern

  require 'aws-sdk-sqs'

  included do
    after_commit on: [:create, :update] do
      # use index_document instead of update_document to also update virtual attributes
      IndexJob.perform_later(self) unless ["ProviderPrefix", "ClientPrefix"].include?(self.class.name)

      if (self.class.name == "DataciteDoi" || self.class.name == "OtherDoi" || self.class.name == "Doi") && (saved_change_to_attribute?("related_identifiers") || saved_change_to_attribute?("creators") || saved_change_to_attribute?("funding_references"))
        send_import_message(self.to_jsonapi) if aasm_state == "findable" && !Rails.env.test?
      elsif self.class.name == "Event"
        OtherDoiJob.perform_later(self.dois_to_import)
      end
    end

    after_touch do
      # use index_document instead of update_document to also update virtual attributes
      IndexBackgroundJob.perform_later(self)
    end

    after_commit on: [:destroy] do
      begin
        __elasticsearch__.delete_document
        if self.class.name == "Event"
          Rails.logger.warn "#{self.class.name} #{uuid} deleted from Elasticsearch index."
        elsif !["ProviderPrefix", "ClientPrefix"].include?(self.class.name)
          Rails.logger.warn "#{self.class.name} #{uid} deleted from Elasticsearch index."
        end
        # send_delete_message(self.to_jsonapi) if self.class.name == "Doi" && !Rails.env.test?
      rescue Elasticsearch::Transport::Transport::Errors::NotFound => e
        Rails.logger.error e.message
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
      if Rails.env == "stage" 
        queue_name_prefix = ENV['ES_PREFIX'].present? ? "stage" : "test"
      else
        queue_name_prefix = Rails.env
      end
      queue_url = sqs.get_queue_url(queue_name: "#{queue_name_prefix}_doi").queue_url
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

    def ror_from_url(url)
      ror = Array(/\A(?:(http|https):\/\/)?(ror\.org\/)?(.+)/.match(url)).last
      "ror.org/#{ror}" if ror.present?
    end
  end

  module ClassMethods
    # return results for one or more ids
    def find_by_id(ids, options={})
      ids = ids.split(",") if ids.is_a?(String)
      options[:page] ||= {}
      options[:page][:number] ||= 1
      options[:page][:size] ||= 2000
    
      if ["Prefix", "ProviderPrefix", "ClientPrefix"].include?(self.name)
        options[:sort] ||= { created_at: { order: "asc" }}
      else
        options[:sort] ||= { created: { order: "asc" }}
      end

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
      elsif options[:totals_agg] == "client_export"
        aggregations = client_export_aggregations
      elsif options[:totals_agg] == "prefix"
        aggregations = prefix_aggregations
      else
        aggregations = query_aggregations
      end

      options[:page] ||= {}
      options[:page][:number] ||= 1
      options[:page][:size] ||= 25

      # Cursor nav use the search after, this should always be an array of values that match the sort.
      if options.fetch(:page, {}).key?(:cursor)
        # make sure we have a valid cursor
        cursor = [0, ""]
        if options.dig(:page, :cursor).is_a?(Array)
          timestamp, uid = options.dig(:page, :cursor)
          cursor = [timestamp.to_i, uid.to_s]
        elsif options.dig(:page, :cursor).is_a?(String)
          timestamp, uid = options.dig(:page, :cursor).split(",")
          cursor = [timestamp.to_i, uid.to_s]
        end

        search_after = cursor
        from = 0
        if self.name == "Event"
          sort = [{ created_at: "asc", uuid: "asc" }]
        elsif self.name == "Activity"
          sort = [{ created: "asc", request_uuid: "asc" }]
        elsif %w(Client Provider).include?(self.name)
          sort = [{ created: "asc", uid: "asc" }]
        elsif %w(Prefix ProviderPrefix ClientPrefix).include?(self.name)
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

      must_not = []
      filter = []

      # filters for some classes
      if self.name == "Provider"
        if query.present?
          must = [{ query_string: { query: query, fields: query_fields, default_operator: "AND", phrase_slop: 1 } }]
        else
          must = [{ match_all: {} }]
        end

        filter << { range: { created: { gte: "#{options[:year].split(",").min}||/y", lte: "#{options[:year].split(",").max}||/y", format: "yyyy" }}} if options[:year].present?
        filter << { range: { updated: { gte: "#{options[:from_date]}||/d" }}} if options[:from_date].present?
        filter << { range: { updated: { lte: "#{options[:until_date]}||/d" }}} if options[:until_date].present?
        filter << { term: { region: options[:region].upcase }} if options[:region].present?
        filter << { term: { "consortium_id.raw" => options[:consortium_id] }} if options[:consortium_id].present?
        filter << { terms: { member_type: options[:member_type].split(",") }} if options[:member_type].present?
        filter << { terms: { organization_type: options[:organization_type].split(",") }} if options[:organization_type].present?
        filter << { term: { non_profit_status: options[:non_profit_status] }} if options[:non_profit_status].present?
        filter << { terms: { focus_area: options[:focus_area].split(",") }} if options[:focus_area].present?

        must_not << { exists: { field: "deleted_at" }} unless options[:include_deleted]
        must_not << { term: { role_name: "ROLE_ADMIN" }}
      elsif self.name == "Client"
        if query.present?
          must = [{ query_string: { query: query, fields: query_fields, default_operator: "AND", phrase_slop: 1 } }]
        else
          must = [{ match_all: {} }]
        end

        filter << { range: { created: { gte: "#{options[:year].split(",").min}||/y", lte: "#{options[:year].split(",").max}||/y", format: "yyyy" }}} if options[:year].present?
        filter << { range: { updated: { gte: "#{options[:from_date]}||/d" }}} if options[:from_date].present?
        filter << { range: { updated: { lte: "#{options[:until_date]}||/d" }}} if options[:until_date].present?
        filter << { terms: { provider_id: options[:provider_id].split(",") }} if options[:provider_id].present?
        filter << { terms: { "software.raw" => options[:software].split(",") }} if options[:software].present?
        filter << { terms: { certificate: options[:certificate].split(",") }} if options[:certificate].present?
        filter << { terms: { repository_type: options[:repository_type].split(",") }} if options[:repository_type].present?
        filter << { term: { consortium_id: options[:consortium_id] }} if options[:consortium_id].present?
        filter << { term: { re3data_id: options[:re3data_id].gsub("/", '\/').upcase }} if options[:re3data_id].present?
        filter << { term: { opendoar_id: options[:opendoar_id] }} if options[:opendoar_id].present?
        filter << { term: { client_type: options[:client_type] }} if options[:client_type].present?
        must_not << { exists: { field: "deleted_at" }} unless options[:include_deleted]
      elsif self.name == "Event"
        if query.present?
          must = [{ query_string: { query: query, fields: query_fields, default_operator: "AND", phrase_slop: 1 } }]
        else
          must = [{ match_all: {} }]
        end

        filter << { term: { subj_id: URI.decode(options[:subj_id]) }} if options[:subj_id].present?
        filter << { term: { obj_id: URI.decode(options[:obj_id]) }} if options[:obj_id].present?
        filter << { term: { citation_type: options[:citation_type] }} if options[:citation_type].present?
        filter << { term: { year_month: options[:year_month] }} if options[:year_month].present?
        filter << { range: { "subj.datePublished" => { gte: "#{options[:publication_year].split("-").min}||/y", lte: "#{options[:publication_year].split("-").max}||/y", format: "yyyy" }}} if options[:publication_year].present?
        filter << { range: { occurred_at: { gte: "#{options[:occurred_at].split("-").min}||/y", lte: "#{options[:occurred_at].split("-").max}||/y", format: "yyyy" }}} if options[:occurred_at].present?
        filter << { terms: { prefix: options[:prefix].split(",") }} if options[:prefix].present?
        filter << { terms: { doi: options[:doi].downcase.split(",") }} if options[:doi].present?
        filter << { terms: { source_doi: options[:source_doi].downcase.split(",") }} if options[:source_doi].present?
        filter << { terms: { target_doi: options[:target_doi].downcase.split(",") }} if options[:target_doi].present?
        filter << { terms: { orcid: options[:orcid].split(",") }} if options[:orcid].present?
        filter << { terms: { isni: options[:isni].split(",") }} if options[:isni].present?
        filter << { terms: { subtype: options[:subtype].split(",") }} if options[:subtype].present?
        filter << { terms: { source_id: options[:source_id].split(",") }} if options[:source_id].present?
        filter << { terms: { relation_type_id: options[:relation_type_id].split(",") }} if options[:relation_type_id].present?
        filter << { terms: { source_relation_type_id: options[:source_relation_type_id].split(",") }} if options[:source_relation_type_id].present?
        filter << { terms: { target_relation_type_id: options[:target_relation_type_id].split(",") }} if options[:target_relation_type_id].present?
        filter << { terms: { registrant_id: options[:registrant_id].split(",") }} if options[:registrant_id].present?
        filter << { terms: { registrant_id: options[:provider_id].split(",") }} if options[:provider_id].present?
        filter << { terms: { issn: options[:issn].split(",") }} if options[:issn].present?

        must_not << { exists: { field: "target_doi" }} if options[:update_target_doi].present?
      elsif self.name == "Prefix"
        if query.present?
          must = [{ prefix: { prefix: query }}]
        else
          must = [{ match_all: {} }]
        end

        filter << { range: { created_at: { gte: "#{options[:year].split(",").min}||/y", lte: "#{options[:year].split(",").max}||/y", format: "yyyy" }}} if options[:year].present?
        filter << { terms: { provider_ids: options[:provider_id].split(",") }} if options[:provider_id].present?
        filter << { terms: { client_ids: options[:client_id].to_s.split(",") }} if options[:client_id].present?
        filter << { terms: { state: options[:state].to_s.split(",") }} if options[:state].present?
      elsif self.name == "ProviderPrefix"
        if query.present?
          must = [{ prefix: { prefix_id: query }}]
        else
          must = [{ match_all: {} }]
        end
        
        filter << { range: { created_at: { gte: "#{options[:year].split(",").min}||/y", lte: "#{options[:year].split(",").max}||/y", format: "yyyy" }}} if options[:year].present?
        filter << { terms: { provider_id: options[:provider_id].split(",") }} if options[:provider_id].present?
        filter << { terms: { provider_id: options[:consortium_organization_id].split(",") }} if options[:consortium_organization_id].present?
        filter << { term: { consortium_id: options[:consortium_id] }} if options[:consortium_id].present?
        filter << { term: { prefix_id: options[:prefix_id] }} if options[:prefix_id].present?
        filter << { terms: { uid: options[:uid].to_s.split(",") }} if options[:uid].present?
        filter << { terms: { state: options[:state].to_s.split(",") }} if options[:state].present?
      elsif self.name == "ClientPrefix"
        if query.present?
          must = [{ prefix: { prefix_id: query }}]
        else
          must = [{ match_all: {} }]
        end
        
        filter << { range: { created_at: { gte: "#{options[:year].split(",").min}||/y", lte: "#{options[:year].split(",").max}||/y", format: "yyyy" }}} if options[:year].present?
        filter << { terms: { client_id: options[:client_id].split(",") }} if options[:client_id].present?
        filter << { term: { prefix_id: options[:prefix_id] }} if options[:prefix_id].present?
      end

      # ES query can be optionally defined in different ways
      # So here we build it differently based upon options
      # This is mostly useful when trying to wrap it in a function_score query
      es_query = {}

      # The main bool query with filters
      bool_query = {
        must: must,
        must_not: must_not,
        filter: filter
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
            aggregations: aggregations,
            track_total_hits: true
          }.compact)
        Hashie::Mash.new({
          total: response.dig("hits", "total", "value"),
          results: response.dig("hits", "hits").map { |r| r["_source"] },
          scroll_id: response["_scroll_id"]
        })
      elsif options.fetch(:page, {}).key?(:cursor)
        __elasticsearch__.search({
          size: options.dig(:page, :size),
          search_after: search_after,
          sort: sort,
          query: es_query,
          aggregations: aggregations,
          track_total_hits: true
        }.compact)
      else
        __elasticsearch__.search({
          size: options.dig(:page, :size),
          from: from,
          sort: sort,
          query: es_query,
          aggregations: aggregations,
          track_total_hits: true
        }.compact)
      end
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
    # For initial setup run "create_index".
    #
    # Run "upgrade_index" whenever there are changes in the mappings or settings.
    # Follow this by "import" to fill the new index, the usen "switch_index" to
    # alias the new index and remove alias from current index.
    #
    # TODO: automatically switch aliases when "import" is done. Not easy, as "import"
    # runs as background jobs.

    # track reindexing via the tasks API
    def monitor_reindex
      client = Elasticsearch::Model.client
      tasks = client.tasks.list(actions: "*reindex")
      tasks.fetch("nodes", {}).inspect
    end

    # create alias
    def create_alias(options={})
      alias_name = options[:alias] || self.index_name
      index_name = options[:index] || self.index_name + "_v1"
      alternate_index_name = options[:index] || self.index_name + "_v2"

      client = Elasticsearch::Model.client

      # indexes in DOI model are aliased from DataciteDoi and OtherDoi models
      # TODO switch to DataciteDoi index
      # if self.name == "Doi"
      #   datacite_index_name = DataciteDoi.index_name + "_v1"
      #   datacite_alternate_index_name = DataciteDoi.index_name + "_v2"
      #   other_index_name = OtherDoi.index_name + "_v1"
      #   other_alternate_index_name = OtherDoi.index_name + "_v2"

      #   if client.indices.exists_alias?(name: alias_name, index: [datacite_index_name])
      #     "Alias #{alias_name} for index #{datacite_index_name} already exists."
      #   else
      #     client.indices.put_alias index: datacite_index_name, name: alias_name
      #     "Created alias #{alias_name} for index #{datacite_index_name}."          
      #   end
      #   if client.indices.exists_alias?(name: alias_name, index: [other_index_name])
      #     "Alias #{alias_name} for index #{other_index_name} already exists."
      #   else
      #     client.indices.put_alias index: other_index_name, name: alias_name
      #     "Created alias #{alias_name} for index #{other_index_name}."
      #   end
      # else
        if client.indices.exists_alias?(name: alias_name, index: [index_name])
          "Alias #{alias_name} for index #{index_name} already exists."
        else
          client.indices.put_alias index: index_name, name: alias_name
          "Created alias #{alias_name} for index #{index_name}."          
        end
      # end
    end

    # list all aliases
    def list_aliases
      client = Elasticsearch::Model.client
      cat_client = Elasticsearch::API::Cat::CatClient.new(client)
      puts cat_client.aliases(s: "alias")
    end

    # delete alias
    def delete_alias(options={})
      alias_name = options[:alias] || self.index_name
      index_name = (options[:index] || self.index_name) + "_v1"
      alternate_index_name = (options[:index] || self.index_name) + "_v2"

      client = Elasticsearch::Model.client

      # indexes in DOI model are aliased from DataciteDoi and OtherDoi models
      # TODO switch to DataciteDoi index
      # if self.name == "Doi"
      #   datacite_index_name = DataciteDoi.index_name + "_v1"
      #   datacite_alternate_index_name = DataciteDoi.index_name + "_v2"
      #   other_index_name = OtherDoi.index_name + "_v1"
      #   other_alternate_index_name = OtherDoi.index_name + "_v2"

      #   if client.indices.exists_alias?(name: alias_name, index: [datacite_index_name])
      #     client.indices.delete_alias index: datacite_index_name, name: alias_name
      #     "Deleted alias #{alias_name} for index #{datacite_index_name}."
      #   end
      #   if client.indices.exists_alias?(name: alias_name, index: [datacite_alternate_index_name])
      #     client.indices.delete_alias index: datacite_alternate_index_name, name: alias_name
      #     "Deleted alias #{alias_name} for index #{datacite_alternate_index_name}."
      #   end
      #   if client.indices.exists_alias?(name: alias_name, index: [other_index_name])
      #     client.indices.delete_alias index: other_index_name, name: alias_name
      #     "Deleted alias #{alias_name} for index #{other_index_name}."
      #   end
      #   if client.indices.exists_alias?(name: alias_name, index: [other_alternate_index_name])
      #     client.indices.delete_alias index: other_alternate_index_name, name: alias_name
      #     "Deleted alias #{alias_name} for index #{other_alternate_index_name}."
      #   end
      # else
        if client.indices.exists_alias?(name: alias_name, index: [index_name])
          client.indices.delete_alias index: index_name, name: alias_name
          "Deleted alias #{alias_name} for index #{index_name}."
        end
        if client.indices.exists_alias?(name: alias_name, index: [alternate_index_name])
          client.indices.delete_alias index: alternate_index_name, name: alias_name
          "Deleted alias #{alias_name} for index #{alternate_index_name}."
        end
      # end
    end

    # create both indexes used for aliasing
    def create_index(options={})
      alias_name = options[:alias] || self.index_name
      index_name = (options[:index] || self.index_name) + "_v1"
      alternate_index_name = (options[:index] || self.index_name) + "_v2"
      client = Elasticsearch::Model.client

      # delete index if it has the same name as the alias
      self.__elasticsearch__.delete_index!(index: alias_name) if self.__elasticsearch__.index_exists?(index: alias_name) && !client.indices.exists_alias?(name: alias_name)

      if self.name == "DataciteDoi" || self.name == "OtherDoi"
        self.create_template
      end

      # indexes in DOI model are aliased from DataciteDoi and OtherDoi models
      # TODO switch to DataciteDoi index
      # if self.name == "Doi"
      #   datacite_index_name = DataciteDoi.index_name + "_v1"
      #   datacite_alternate_index_name = DataciteDoi.index_name + "_v2"
      #   other_index_name = OtherDoi.index_name + "_v1"
      #   other_alternate_index_name = OtherDoi.index_name + "_v2"

      #   self.__elasticsearch__.create_index!(index: datacite_index_name) unless self.__elasticsearch__.index_exists?(index: datacite_index_name)
      #   self.__elasticsearch__.create_index!(index: datacite_alternate_index_name) unless self.__elasticsearch__.index_exists?(index: datacite_alternate_index_name)
      #   self.__elasticsearch__.create_index!(index: other_index_name) unless self.__elasticsearch__.index_exists?(index: other_index_name)
      #   self.__elasticsearch__.create_index!(index: other_alternate_index_name) unless self.__elasticsearch__.index_exists?(index: other_alternate_index_name)
      
      #   "Created indexes #{datacite_index_name}, #{other_index_name}, #{datacite_alternate_index_name}, and #{other_alternate_index_name}."
      # else
        self.__elasticsearch__.create_index!(index: index_name) unless self.__elasticsearch__.index_exists?(index: index_name)
        self.__elasticsearch__.create_index!(index: alternate_index_name) unless self.__elasticsearch__.index_exists?(index: alternate_index_name)

        "Created indexes #{index_name} and #{alternate_index_name}."
      # end
    end

    # delete index and both indexes used for aliasing
    def delete_index(options={})
      client = Elasticsearch::Model.client

      if options[:index]
        self.__elasticsearch__.delete_index!(index: options[:index])
        return "Deleted index #{options[:index]}."
      end

      alias_name = self.index_name
      index_name = self.index_name + "_v1"
      alternate_index_name = self.index_name + "_v2"

      # indexes in DOI model are aliased from DataciteDoi and OtherDoi models
      # TODO switch to DataciteDoi index
      # if self.name == "Doi"
      #   datacite_index_name = DataciteDoi.index_name + "_v1"
      #   datacite_alternate_index_name = DataciteDoi.index_name + "_v2"
      #   other_index_name = OtherDoi.index_name + "_v1"
      #   other_alternate_index_name = OtherDoi.index_name + "_v2"

      #   self.__elasticsearch__.delete_index!(index: datacite_index_name) if self.__elasticsearch__.index_exists?(index: datacite_index_name)
      #   self.__elasticsearch__.delete_index!(index: datacite_alternate_index_name) if self.__elasticsearch__.index_exists?(index: datacite_alternate_index_name)
      #   self.__elasticsearch__.delete_index!(index: other_index_name) if self.__elasticsearch__.index_exists?(index: other_index_name)
      #   self.__elasticsearch__.delete_index!(index: other_alternate_index_name) if self.__elasticsearch__.index_exists?(index: other_alternate_index_name)
      
      #   "Deleted indexes #{datacite_index_name}, #{other_index_name}, #{datacite_alternate_index_name}, and #{other_alternate_index_name}."
      # else
        self.__elasticsearch__.delete_index!(index: index_name) if self.__elasticsearch__.index_exists?(index: index_name)
        self.__elasticsearch__.delete_index!(index: alternate_index_name) if self.__elasticsearch__.index_exists?(index: alternate_index_name)

        "Deleted indexes #{index_name} and #{alternate_index_name}."
      # end
    end

    # list all indices
    def list_indices
      client = Elasticsearch::Model.client
      cat_client = Elasticsearch::API::Cat::CatClient.new(client)
      puts cat_client.indices(s: "index")
    end

    # delete and create inactive index to use current mappings
    # Needs to run every time we change the mappings
    def upgrade_index(options={})
      inactive_index ||= (options[:index] || self.inactive_index)

      self.__elasticsearch__.create_index!(index: inactive_index, force: true)
      "Upgraded inactive index #{inactive_index}."
    end

    # show stats for both indexes
    def index_stats(options={})
      active_index = options[:active_index] || self.active_index
      inactive_index = options[:inactive_index] || self.inactive_index
      client = Elasticsearch::Model.client

      # TODO switch to DataciteDoi index
      # if self.name == "Doi"
      #   datacite_active_index = DataciteDoi.active_index
      #   datacite_inactive_index = DataciteDoi.inactive_index
      #   other_active_index = OtherDoi.active_index
      #   other_inactive_index = OtherDoi.inactive_index

      #   stats = client.indices.stats index: [datacite_active_index, datacite_inactive_index], docs: true
      #   active_index_count = stats.dig("indices", datacite_active_index, "primaries", "docs", "count")
      #   inactive_index_count = stats.dig("indices", datacite_inactive_index, "primaries", "docs", "count")
      #   database_count = DataciteDoi.all.count

      #   "Active index #{active_index} has #{active_index_count} documents, " \
      #     "inactive index #{inactive_index} has #{inactive_index_count} documents, " \
      #     "database has #{database_count} documents."

      #   stats = client.indices.stats index: [other_active_index, other_inactive_index], docs: true
      #   active_index_count = stats.dig("indices", other_active_index, "primaries", "docs", "count")
      #   inactive_index_count = stats.dig("indices", other_inactive_index, "primaries", "docs", "count")
      #   database_count = OtherDoi.all.count

      #   "Active index #{active_index} has #{active_index_count} documents, " \
      #     "inactive index #{inactive_index} has #{inactive_index_count} documents, " \
      #     "database has #{database_count} documents."
      # else
        stats = client.indices.stats index: [active_index, inactive_index], docs: true
        active_index_count = stats.dig("indices", active_index, "primaries", "docs", "count")
        inactive_index_count = stats.dig("indices", inactive_index, "primaries", "docs", "count")
        database_count = self.all.count

        "Active index #{active_index} has #{active_index_count} documents, " \
          "inactive index #{inactive_index} has #{inactive_index_count} documents, " \
          "database has #{database_count} documents."
      # end
    end

    # switch between the two indexes, i.e. the index that is aliased
    def switch_index(options={})
      alias_name = options[:alias] || self.index_name
      index_name = (options[:index] || self.index_name) + "_v1"
      alternate_index_name = (options[:index] || self.index_name) + "_v2"

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

      # TODO switch to DataCiteDoi index
      # if self.name == "Doi"
      #   datacite_index_name = DataciteDoi.index_name + "_v1"
      #   datacite_alternate_index_name = DataciteDoi.index_name + "_v2"
      #   other_index_name = OtherDoi.index_name + "_v1"
      #   other_alternate_index_name = OtherDoi.index_name + "_v2"

      #   if client.indices.exists_alias?(name: alias_name, index: [datacite_index_name])
      #     client.indices.update_aliases body: {
      #       actions: [
      #         { remove: { index: datacite_index_name, alias: alias_name } },
      #         { add:    { index: datacite_alternate_index_name, alias: alias_name } }
      #       ]
      #     }

      #     "Switched active index for alias #{alias_name} to #{datacite_alternate_index_name}."
      #   elsif client.indices.exists_alias?(name: alias_name, index: [datacite_alternate_index_name])
      #     client.indices.update_aliases body: {
      #       actions: [
      #         { remove: { index: datacite_alternate_index_name, alias: alias_name } },
      #         { add:    { index: datacite_index_name, alias: alias_name } }
      #       ]
      #     }

      #     "Switched active index  for alias #{alias_name} to #{datacite_index_name}."
      #   end

      #   if client.indices.exists_alias?(name: alias_name, index: [other_index_name])
      #     client.indices.update_aliases body: {
      #       actions: [
      #         { remove: { index: other_index_name, alias: alias_name } },
      #         { add:    { index: other_alternate_index_name, alias: alias_name } }
      #       ]
      #     }

      #     "Switched active index for alias #{alias_name} to #{other_alternate_index_name}."
      #   elsif client.indices.exists_alias?(name: alias_name, index: [other_alternate_index_name])
      #     client.indices.update_aliases body: {
      #       actions: [
      #         { remove: { index: other_alternate_index_name, alias: alias_name } },
      #         { add:    { index: other_index_name, alias: alias_name } }
      #       ]
      #     }

      #     "Switched active index for alias #{alias_name} to #{other_index_name}."
      #   end
      # elsif self.name == "DataciteDoi" || self.name == "OtherDoi"
      #   if client.indices.exists_alias?(name: alias_name, index: [index_name])
      #     client.indices.update_aliases body: {
      #       actions: [
      #         { remove: { index: index_name, alias: alias_name } },
      #         { remove: { index: index_name, alias: Doi.index_name } },
      #         { add:    { index: alternate_index_name, alias: alias_name } },
      #         { add:    { index: alternate_index_name, alias: Doi.index_name } }
      #       ]
      #     }

      #     "Switched active index for aliases #{alias_name} and #{Doi.index_name} to #{alternate_index_name}."
      #   elsif client.indices.exists_alias?(name: alias_name, index: [alternate_index_name])
      #     client.indices.update_aliases body: {
      #       actions: [
      #         { remove: { index: alternate_index_name, alias: alias_name } },
      #         { remove: { index: alternate_index_name, alias: Doi.index_name } },
      #         { add:    { index: index_name, alias: alias_name } },
      #         { add:    { index: index_name, alias: Doi.index_name } }
      #       ]
      #     }

      #     "Switched active index for aliases #{alias_name} and #{Doi.index_name} to #{index_name}."
      #   end
      # else
      #   if client.indices.exists_alias?(name: alias_name, index: [index_name])
      #     client.indices.update_aliases body: {
      #       actions: [
      #         { remove: { index: index_name, alias: alias_name } },
      #         { add:    { index: alternate_index_name, alias: alias_name } }
      #       ]
      #     }

      #     "Switched active index for alias #{alias_name} to #{alternate_index_name}."
      #   elsif client.indices.exists_alias?(name: alias_name, index: [alternate_index_name])
      #     client.indices.update_aliases body: {
      #       actions: [
      #         { remove: { index: alternate_index_name, alias: alias_name } },
      #         { add:    { index: index_name, alias: alias_name } }
      #       ]
      #     }

      #     "Switched active index for alias #{alias_name} to #{index_name}."
      #   end
      # end
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

    # create index template 
    def create_template
      alias_name = self.index_name

      if self.name == "Doi" || self.name == "DataciteDoi" || self.name == "OtherDoi"
        body = {
          index_patterns: ["dois*"],
          settings: Doi.settings.to_hash,
          mappings: Doi.mappings.to_hash
        }
      else
        body = {
          index_patterns: ["#{alias_name}*"],
          settings: self.settings.to_hash,
          mappings: self.mappings.to_hash
        }
      end

      client = Elasticsearch::Model.client
      exists = client.indices.exists_template?(name: alias_name)
      response = client.indices.put_template(name: alias_name, body: body) 
      
      if response.to_h["acknowledged"]
        exists ? "Updated template #{alias_name}." : "Created template #{alias_name}."
      else
        exists ? "An error occured updating template #{alias_name}." : "An error occured creating template #{alias_name}."
      end
    end

    # list all templates
    def list_templates(options={})
      client = Elasticsearch::Model.client
      cat_client = Elasticsearch::API::Cat::CatClient.new(client)
      puts cat_client.templates(name: options[:name])
    end

    # delete index template 
    def delete_template
      alias_name = self.index_name

      client = Elasticsearch::Model.client
      if client.indices.exists_template?(name: alias_name)
        response = client.indices.delete_template(name: alias_name)
        
        if response.to_h["acknowledged"]
          "Deleted template #{alias_name}."
        else
          "An error occured deleting template #{alias_name}."
        end
      else
        "Template #{alias_name} does not exist."
      end
    end
      
    def doi_from_url(url)
      if /\A(?:(http|https):\/\/(dx\.)?(doi.org|handle.test.datacite.org)\/)?(doi:)?(10\.\d{4,5}\/.+)\z/.match?(url)
        uri = Addressable::URI.parse(url)
        uri.path.gsub(/^\//, "").downcase
      end
    end

    def orcid_from_url(url)
      Array(/\A(?:(http|https):\/\/)?(orcid\.org\/)?(.+)/.match(url)).last
    end

    def ror_from_url(url)
      ror = Array(/\A(?:(http|https):\/\/)?(ror\.org\/)?(.+)/.match(url)).last
      "ror.org/#{ror}" if ror.present?
    end
  end
end
