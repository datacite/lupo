module Indexable
  extend ActiveSupport::Concern

  require 'aws-sdk-sqs'

  included do
    after_commit on: [:create, :update] do
      # use index_document instead of update_document to also update virtual attributes
      IndexJob.perform_later(self)
      if self.class.name == "Doi"
        update_column(:indexed, Time.zone.now)
        send_import_message(self.to_jsonapi) if aasm_state == "findable" unless (Rails.env.test? || client_id == "crossref.citations")
      end
    end

    after_touch do
      # use index_document instead of update_document to also update virtual attributes
      IndexJob.perform_later(self)
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
        query: {
          terms: {
            id: ids.split(",")
          }
        },
        aggregations: query_aggregations
      })
    end

    def query(query, options={})
      aggregations = options[:totals_agg] == true ? totals_aggregations : query_aggregations
      options[:page] ||= {}
      options[:page][:number] ||= 1
      options[:page][:size] ||= 25

      # enable cursor-based pagination for DOIs
      if self.name == "Doi" && options.dig(:page, :cursor).present?
        from = 0
        search_after = [options.dig(:page, :cursor)]
        sort = [{ _id: { order: 'asc' }}]
      elsif self.name == "Activity" && options.dig(:page, :cursor).present?
        from = 0
        search_after = [options.dig(:page, :cursor)]
        sort = [{ created: { order: 'asc' }}]
      elsif options.dig(:page, :cursor).present?
        from = 0
        search_after = [options.dig(:page, :cursor)]
        sort = [{ created: { order: 'asc' }}]
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
      must << { term: { "author.id" => "https://orcid.org/#{options[:person_id]}" }} if options[:person_id].present?
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
        must << { term: { member_type: options[:member_type] }} if options[:member_type].present?
        must << { term: { organization_type: options[:organization_type] }} if options[:organization_type].present?
        must << { term: { focus_area: options[:focus_area] }} if options[:focus_area].present?

        must_not << { exists: { field: "deleted_at" }} unless options[:include_deleted]
        if options[:exclude_registration_agencies]
          must_not << { terms: { role_name: ["ROLE_ADMIN", "ROLE_REGISTRATION_AGENCY"] }}
        else
          must_not << { term: { role_name: "ROLE_ADMIN" }}
        end
      elsif self.name == "Client"
        must << { range: { created: { gte: "#{options[:year].split(",").min}||/y", lte: "#{options[:year].split(",").max}||/y", format: "yyyy" }}} if options[:year].present?
        must << { terms: { "software.raw" => options[:software].split(",") }} if options[:software].present?
        must_not << { exists: { field: "deleted_at" }} unless options[:include_deleted]
        must_not << { terms: { provider_id: ["crossref"] }} if options[:exclude_registration_agencies]
      elsif self.name == "Doi"
        must << { terms: { aasm_state: options[:state].to_s.split(",") }} if options[:state].present?
        must << { range: { registered: { gte: "#{options[:registered].split(",").min}||/y", lte: "#{options[:registered].split(",").max}||/y", format: "yyyy" }}} if options[:registered].present?
        must << { term: { "client.repository_id": options[:repository_id].upcase }} if options[:repository_id].present?
        must_not << { terms: { provider_id: ["crossref"] }} if options[:exclude_registration_agencies]
      elsif self.name == "Event"
        must << { term: { subj_id: options[:subj_id] }} if options[:subj_id].present?
        must << { term: { obj_id: options[:obj_id] }} if options[:obj_id].present?
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

      __elasticsearch__.search({
        size: options.dig(:page, :size),
        from: from,
        search_after: search_after,
        sort: sort,
        query: es_query,
        aggregations: aggregations
      }.compact)
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

    def create_alias(index: nil)
      return nil unless index.present?

      client     = self.gateway.client
      index_name = self.index_name

      client.indices.put_alias index: index, name: index_name
    end

    def update_aliases(old_index: nil, new_index: nil)
      return nil unless old_index.present? && new_index.present?
      
      client     = self.gateway.client
      index_name = self.index_name

      client.indices.update_aliases body: {
        actions: [
          { remove: { index: old_index, alias: index_name } },
          { add:    { index: new_index, alias: index_name } }
        ]
      }
    end
  end
end
