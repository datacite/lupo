module Indexable
  extend ActiveSupport::Concern

  require 'aws-sdk-sqs'

  included do
    after_commit on: [:create] do
      __elasticsearch__.index_document
    end
  
    after_commit on: [:update] do
      # use index_document instead of update_document to also update virtual attributes
      __elasticsearch__.index_document
    end
  
    after_commit on: [:destroy] do
      __elasticsearch__.delete_document
    end

    # unless Rails.env.test?
    #   before_destroy { send_delete_message(self.to_jsonapi) }
    #   after_save { send_import_message(self.to_jsonapi) }
    # end

    def send_delete_message(data)
      send_message(data, shoryuken_class: "ElasticDeleteWorker")
    end

    def send_import_message(data)
      send_message(data, shoryuken_class: "ElasticImportWorker")
    end
    
    # shoryuken_class is needed for the consumer to process the message
    # we use the AWS SQS client directly as there is no consumer in this app
    def send_message(body, options={})
      sqs = Aws::SQS::Client.new
      queue_url = sqs.get_queue_url(queue_name: "#{Rails.env}_elastic").queue_url
      options[:shoryuken_class] ||= "ElasticImportWorker"

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
        from: options[:from] || 0,
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
        from: options[:from] || 0,
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
      options[:sort] ||= { "_doc" => { order: 'asc' }}

      must = []
      must << { multi_match: { query: query, fields: query_fields, type: "phrase_prefix", max_expansions: 50 }} if query.present?
      must << { term: { aasm_state: options[:state] }} if options[:state].present?
      must << { term: { resource_type_general: options[:resource_type_id] }} if options[:resource_type_id].present?
      must << { terms: { provider_id: options[:provider_id].split(",") }} if options[:provider_id].present?
      must << { terms: { client_id: options[:client_id].split(",") }} if options[:client_id].present?
      must << { term: { prefix: options[:prefix] }} if options[:prefix].present?
      must << { term: { "author.id" => "https://orcid.org/#{options[:person_id]}" }} if options[:person_id].present?
      must << { range: { created: { gte: "#{options[:created].split(",").min}||/y", lte: "#{options[:created].split(",").max}||/y", format: "yyyy" }}} if options[:created].present?
      must << { term: { schema_version: "http://datacite.org/schema/kernel-#{options[:schema_version]}" }} if options[:schema_version].present?
      must << { term: { source: options[:source] }} if options[:source].present?

      must_not = []

      # filters for some classes
      if self.name == "Provider"
        must << { range: { created: { gte: "#{options[:year].split(",").min}||/y", lte: "#{options[:year].split(",").max}||/y", format: "yyyy" }}} if options[:year].present?
        must << { term: { role_name: "ROLE_ALLOCATOR" }} 
        must_not << { exists: { field: "deleted_at" }}
      elsif self.name == "Client"
        must << { range: { created: { gte: "#{options[:year].split(",").min}||/y", lte: "#{options[:year].split(",").max}||/y", format: "yyyy" }}} if options[:year].present?
        must_not << { exists: { field: "deleted_at" }}
      elsif self.name == "Doi"
        must << { range: { published: { gte: "#{options[:year].split(",").min}||/y", lte: "#{options[:year].split(",").max}||/y", format: "yyyy" }}} if options[:year].present?
      end

      __elasticsearch__.search({
        from: options[:from] || 0,
        size: options[:size] || 25,
        sort: [options[:sort]],
        query: {
          bool: {
            must: must,
            must_not: must_not
          }
        },
        aggregations: query_aggregations
      })
    end

    def recreate_index(options={})
      client     = self.gateway.client
      index_name = self.index_name

      client.indices.delete index: index_name rescue nil if options[:force]
      client.indices.create index: index_name, body: { settings:  {"index.requests.cache.enable": true }}
    end
  end
end
