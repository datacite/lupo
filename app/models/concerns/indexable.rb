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

      fields = options[:query_fields].presence || query_fields

      must = []
      must << { multi_match: { query: query, fields: fields, type: "phrase_prefix", slop: 3, max_expansions: 10 }} if query.present?
      must << { term: { aasm_state: options[:state] }} if options[:state].present?
      must << { term: { resource_type_id: options[:resource_type_id] }} if options[:resource_type_id].present?
      must << { terms: { provider_id: options[:provider_id].split(",") }} if options[:provider_id].present?
      must << { terms: { client_id: options[:client_id].split(",") }} if options[:client_id].present?
      must << { term: { prefix: options[:prefix] }} if options[:prefix].present?
      must << { term: { "author.id" => "https://orcid.org/#{options[:person_id]}" }} if options[:person_id].present?
      must << { range: { created: { gte: "#{options[:created].split(",").min}||/y", lte: "#{options[:created].split(",").max}||/y", format: "yyyy" }}} if options[:created].present?
      must << { range: { registered: { gte: "#{options[:registered].split(",").min}||/y", lte: "#{options[:registered].split(",").max}||/y", format: "yyyy" }}} if options[:registered].present?
      must << { term: { schema_version: "http://datacite.org/schema/kernel-#{options[:schema_version]}" }} if options[:schema_version].present?
      must << { term: { source: options[:source] }} if options[:source].present?
      must << { term: { last_landing_page_status: options[:link_check_status] }} if options[:link_check_status].present?

      must_not = []

      # filters for some classes
      if self.name == "Provider"
        must << { range: { created: { gte: "#{options[:year].split(",").min}||/y", lte: "#{options[:year].split(",").max}||/y", format: "yyyy" }}} if options[:year].present?
        must << { term: { region: options[:region].upcase }} if options[:region].present?
        must << { term: { organization_type: options[:organization_type] }} if options[:organization_type].present?
        must << { term: { focus_area: options[:focus_area] }} if options[:focus_area].present?
        must << { term: { role_name: "ROLE_ALLOCATOR" }} unless options[:all_members]
        must_not << { exists: { field: "deleted_at" }} unless options[:include_deleted]
      elsif self.name == "Client"
        must << { range: { created: { gte: "#{options[:year].split(",").min}||/y", lte: "#{options[:year].split(",").max}||/y", format: "yyyy" }}} if options[:year].present?
        must_not << { exists: { field: "deleted_at" }} unless options[:include_deleted]
      elsif self.name == "Doi"
        must << { range: { published: { gte: "#{options[:year].split(",").min}||/y", lte: "#{options[:year].split(",").max}||/y", format: "yyyy" }}} if options[:year].present?
      end

      __elasticsearch__.search({
        size: options.dig(:page, :size),
        from: from,
        search_after: search_after,
        sort: sort,
        query: {
          bool: {
            must: must,
            must_not: must_not
          }
        },
        aggregations: query_aggregations
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
