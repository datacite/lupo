module Indexable
  extend ActiveSupport::Concern

  require 'aws-sdk-sqs'

  included do
    after_commit on: [:create, :update] do
      # use index_document instead of update_document to also update virtual attributes
      IndexJob.perform_later(self)
      if self.class.name == "Doi"
        update_column(:indexed, Time.zone.now)
        send_import_message(self.to_jsonapi) if aasm_state == "findable" unless Rails.env.test?
      end
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
    # don't raise an exception when not found
    def find_by_id(id, options={})
      return nil unless id.present?

      __elasticsearch__.search({
        query: {
          term: {
            symbol: id.upcase
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

    def find_by_ids(ids, options={})
      options[:sort] ||= { "_doc" => { order: 'asc' }}

      __elasticsearch__.search({
        from: options[:page].present? ? (options.dig(:page, :number) - 1) * options.dig(:page, :size) : 0,
        size: options[:size] || 25,
        sort: [options[:sort]],
        query: {
          terms: {
            symbol: ids.split(",").map(&:upcase)
          }
        },
        aggregations: query_aggregations
      })
    end

    def query(query, options={})
      aggregations = query_aggregations

      # enable cursor-based pagination for DOIs
      if self.name == "Doi" && options.dig(:page, :cursor).present?
        from = 0
        search_after = [options.dig(:page, :cursor)]
        sort = [{ updated: { order: 'asc' }}]
      else
        from = (options.dig(:page, :number) - 1) * options.dig(:page, :size)
        search_after = nil
        sort = options[:sort]
      end

      # currently not used
      # fields = options[:query_fields].presence || query_fields

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
      must << { query_string: { query: query }} if query.present?
      must << { term: { aasm_state: options[:state] }} if options[:state].present?
      must << { term: { "types.resourceTypeGeneral": options[:resource_type_id].underscore.camelize }} if options[:resource_type_id].present?
      must << { terms: { provider_id: options[:provider_id].split(",") }} if options[:provider_id].present?
      must << { terms: { client_id: options[:client_id].to_s.split(",") }} if options[:client_id].present?
      must << { term: { prefix: options[:prefix] }} if options[:prefix].present?
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
        must << { term: { organization_type: options[:organization_type] }} if options[:organization_type].present?
        must << { term: { focus_area: options[:focus_area] }} if options[:focus_area].present?

        if options[:all_members]
          must << { terms: { role_name: %w(ROLE_ALLOCATOR ROLE_MEMBER) }}
        else
          must << { term: { role_name: "ROLE_ALLOCATOR" }}
        end

        must_not << { exists: { field: "deleted_at" }} unless options[:include_deleted]
      elsif self.name == "Client"
        must << { range: { created: { gte: "#{options[:year].split(",").min}||/y", lte: "#{options[:year].split(",").max}||/y", format: "yyyy" }}} if options[:year].present?
        must << { terms: { "software.raw" => options[:software].split(",") }} if options[:software].present?
        must_not << { exists: { field: "deleted_at" }} unless options[:include_deleted]
      elsif self.name == "Doi"
        must << { range: { registered: { gte: "#{options[:registered].split(",").min}||/y", lte: "#{options[:registered].split(",").max}||/y", format: "yyyy" }}} if options[:registered].present?
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
  end
end
