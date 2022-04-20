# frozen_string_literal: true

class ReferenceRepository < ApplicationRecord
  include Indexable
  include Elasticsearch::Model
  include Elasticsearch::Model::Callbacks
  include Hashid::Rails

  before_save :force_index

  validates_uniqueness_of :re3doi, allow_nil: true
  #
  # use different index for testing
  if Rails.env.test?
    index_name "refernce_repositories-test"
  elsif ENV["ES_PREFIX"].present?
    index_name "refernce_repositories-#{ENV['ES_PREFIX']}"
  else
    index_name "refernce_repositories"
  end

  def self.find_client(client_id)
    ::Client.where(symbol: client_id).where(deleted_at: nil).first
  end

  def self.find_re3(doi)
    DataCatalog.find_by_id(doi).fetch(:data, []).first
  end

  def uid
    hashid
  end

  def client_repo
    if @dsclient&.symbol == self[:client_id]
      @dsclient
    else
      @dsclient = ReferenceRepository.find_client(self[:client_id])
    end
  end

  def re3_repo
    @re3repo ||= ReferenceRepository.find_re3(self[:re3doi])
  end

  def as_indexed_json(_options = {})
    ReferenceRepositoryDenormalizer.new(self).to_hash
  end

  settings index: { number_of_shards: 1 } do
    mapping dynamic: "false" do
      indexes :id
      indexes :uid
      indexes :client_id
      indexes :re3doi
      indexes :re3data_url
      indexes :created_at, type: :date, format: :date_optional_time
      indexes :updated_at, type: :date, format: :date_optional_time
      indexes :name
      indexes :alternate_name
      indexes :description
      indexes :pid_system, type: :keyword
      indexes :url
      indexes :keyword, type: :keyword
      indexes :contact
      indexes :language, type: :keyword
      indexes :certificate, type: :keyword
      indexes :data_access, type: :object,
          properties: {
              type: { type: :keyword },
              restrictions: { type: :text }
          }
      indexes :data_upload, type: :object,
          properties: {
              type: { type: :keyword },
              restrictions: { type: :text }
          }
      indexes :provider_type, type: :keyword
      indexes :repository_type, type: :keyword
      indexes :data_upload_licenses, type: :keyword
      indexes :software, type: :keyword
      indexes :subject, type: :object,
          properties: {
              text: { type: :keyword },
              id: { type: :keyword },
              scheme: { type: :keyword }
          }
      indexes :re3_created, type: :date
      indexes :re3_updated, type: :date
    end
  end

  def force_index
    __elasticsearch__.instance_variable_set(:@__changed_model_attributes, nil)
  end

  class << self
    def query_aggregations(facet_count: 10)
      if facet_count.positive?
        {
          software: {
            terms: {
              field: "software",
              size: facet_count,
              min_doc_count: 1
            },
          },
          repository_types: {
            terms: {
              field: "repository_type",
              size: facet_count,
              min_doc_count: 1
            },
          },
          certificates: {
            terms: {
              field: "certificate",
              size: facet_count,
              min_doc_count: 1
            },
          },
        }
      end
    end

    def id_fields
      %w[
        uid^10
        client_id
        re3doi
      ]
    end

    def find_by_id(ids, options = {})
      ids = ids.split(",") if ids.is_a?(String)
      ids = ids.map { |id| id.gsub("10.17616\/", "") }
      options[:page] ||= {}
      options[:page][:number] ||= 1
      options[:page][:size] ||= 2_000

      options[:sort] ||= { _score: { order: "asc" } }

      __elasticsearch__.search(
        from: (options.dig(:page, :number) - 1) * options.dig(:page, :size),
        size: options.dig(:page, :size),
        sort: [options[:sort]],
        track_total_hits: true,
        query: {
          query_string: {
            fields: id_fields,
            query: ids.join(" OR ")
          }
        },
      )
    end

    def query_fields
      %w[
        uid^10
        name^5
        description^5
        software
        subject.text
        _all
      ]
    end

    def query(query, options = {})
      options[:page] ||= {}
      options[:page][:number] ||= 1
      options[:page][:size] ||= 25
      options[:sort] ||= { _score: { order: "asc" } }

      if options.fetch(:page, {}).key?(:cursor)
        cursor = [0]
        if options.dig(:page, :cursor).is_a?(Array)
          timestamp, uid = options.dig(:page, :cursor)
          cursor = [timestamp.to_i, uid.to_s]
        elsif options.dig(:page, :cursor).is_a?(String)
          timestamp, uid = options.dig(:page, :cursor).split(",")
          cursor = [timestamp.to_i, uid.to_s]
        end

        search_after = cursor
        __elasticsearch__.search(
          {
            size: options.dig(:page, :size),
            search_after: search_after,
            sort: [options[:sort]],
            query: es_query(query, options),
            aggregations: query_aggregations,
            track_total_hits: true,
          }.compact,
        )
      else
        from =
          ((options.dig(:page, :number) || 1) - 1) *
          (options.dig(:page, :size) || 25)
        __elasticsearch__.search(
          {
            size: options.dig(:page, :size),
            from: from,
            sort: [options[:sort]],
            query: es_query(query, options),
            aggregations: query_aggregations,
            track_total_hits: true,
          }.compact,
        )
      end
    end

    private
      def must(query)
        if query.present?
          [{
            query_string: {
              query: query,
              fields: query_fields,
              default_operator: "AND",
              phrase_slop: 1,
            },
          }]
        else
          [{ match_all: {} }]

        end
      end

      def filter(options)
        retval = []
        if options[:software].present?
          retval << { terms: {
            "software": options[:software].split(",")
          } }
        end
        if options[:certificate].present?
          retval << { terms: {
            "certificate": options[:certificate].split(",")
          } }
        end
        if options[:repository_type].present?
          retval << { terms: {
            "repository_type": options[:repository_type].split(",")
          } }
        end
        if options[:is_open] == "true"
          retval << { term: {
            "data_access.type": "open"
          } }
        end
        if options[:is_disciplinary] == "true"
          retval << { term: {
            "repository_type": "disciplinary"
          } }
        end
        if options[:is_certified] == "true"
          retval << { regexp: {
            "certificate": ".+"
          } }
        end
        if options[:has_pid] == "true"
          retval << { regexp: {
            pid_system: "doi|hdl|urn|ark"
          } }
        end
        if options[:subject].present?
          retval << { term: {
            "subject.text": options[:subject]
          } }
        end
        if options[:subject_id].present?
          retval << { regexp: {
            "subject.id": options[:subject_id]
          } }
        end
        retval
      end

      def es_query(query, options)
        {
          bool: {
            must: must(query),
            # must_not: must_not,
            filter: filter(options),
            # should: should,
            # minimum_should_match: minimum_should_match
          }
        }
      end
  end
end
