# frozen_string_literal: true

class Event < ApplicationRecord
  # include helper module for query caching
  include Cacheable

  # include event processing
  include Processable

  # include helper methods for models
  include Modelable

  # include doi normalization
  include Identifiable

  # include helper module for Elasticsearch
  include Indexable

  include Elasticsearch::Model

  belongs_to :doi_for_source,
             class_name: "Doi",
             primary_key: :doi,
             foreign_key: :source_doi,
             touch: true,
             optional: true
  belongs_to :doi_for_target,
             class_name: "Doi",
             primary_key: :doi,
             foreign_key: :target_doi,
             touch: true,
             optional: true

  before_validation :set_defaults
  before_create :set_source_and_target_doi

  validate :uuid_format

  # include state machine
  include AASM

  aasm whiny_transitions: false do
    state :waiting, initial: true
    state :working, :failed, :done

    #  Reset after failure
    event :reset do
      transitions from: %i[failed], to: :waiting
    end

    event :start do
      transitions from: %i[waiting], to: :working
    end

    event :finish do
      transitions from: %i[working], to: :done
    end

    event :error do
      transitions to: :failed
    end
  end

  #   after_transition :to => [:failed, :done] do |event|
  #     event.send_callback if event.callback.present?
  #   end

  #   after_transition :failed => :waiting do |event|
  #     event.queue_event_job
  #   end

  serialize :subj, coder: JSON
  serialize :obj, coder: JSON
  serialize :error_messages, coder: JSON

  alias_attribute :created, :created_at
  alias_attribute :updated, :updated_at

  # renamed to make it clearer that these relation types are grouped together as references
  REFERENCE_RELATION_TYPES = %w[
    cites is-supplemented-by references
  ].freeze

  # renamed to make it clearer that these relation types are grouped together as citations
  CITATION_RELATION_TYPES = %w[
    is-cited-by is-supplement-to is-referenced-by
  ].freeze

  INCLUDED_RELATION_TYPES = REFERENCE_RELATION_TYPES | CITATION_RELATION_TYPES

  PART_RELATION_TYPES = %w[
    is-part-of has-part
  ]

  NEW_RELATION_TYPES = %w[ is-reply-to is-translation-of is-published-in ]
  RELATIONS_RELATION_TYPES = %w[
    compiles
    is-compiled-by
    documents
    is-documented-by
    has-metadata
    is-metadata-for
    is-derived-from
    is-source-of
    reviews
    is-reviewed-by
    requires
    is-required-by
    continues
    is-coutinued-by
    has-version
    is-version-of
    has-part
    is-part-of
    is-variant-from-of
    is-original-form-of
    is-identical-to
    obsoletes
    is-obsolete-by
    is-new-version-of
    is-previous-version-of
    describes
    is-described-by
  ].freeze

  ALL_RELATION_TYPES = (RELATIONS_RELATION_TYPES | NEW_RELATION_TYPES | CITATION_RELATION_TYPES | REFERENCE_RELATION_TYPES).uniq

  OTHER_RELATION_TYPES = (
    RELATIONS_RELATION_TYPES | NEW_RELATION_TYPES
  ) - INCLUDED_RELATION_TYPES - PART_RELATION_TYPES

  RELATED_SOURCE_IDS = %w[
    datacite-related
    datacite-crossref
    crossref
  ].freeze

  validates :subj_id, :source_id, :source_token, presence: true

  attr_accessor :container_title, :url

  # use different index for testing
  if Rails.env.test?
    index_name "events-test#{ENV['TEST_ENV_NUMBER']}"
  elsif ENV["ES_PREFIX"].present?
    index_name "events-#{ENV['ES_PREFIX']}"
  else
    index_name "events"
  end

  mapping dynamic: "false" do
    indexes :uuid, type: :keyword
    indexes :subj_id, type: :keyword
    indexes :obj_id, type: :keyword
    indexes :doi, type: :keyword
    indexes :orcid, type: :keyword
    indexes :prefix, type: :keyword
    indexes :subtype, type: :keyword
    indexes :citation_type, type: :keyword
    indexes :issn, type: :keyword
    indexes :subj,
            type: :object,
            properties: {
              type: { type: :keyword },
              id: { type: :keyword },
              uid: { type: :keyword },
              proxyIdentifiers: { type: :keyword },
              datePublished: {
                type: :date,
                format: "date_optional_time||yyyy-MM-dd||yyyy-MM||yyyy",
                ignore_malformed: true,
              },
              registrantId: { type: :keyword },
              cache_key: { type: :keyword },
            }
    indexes :obj,
            type: :object,
            properties: {
              type: { type: :keyword },
              id: { type: :keyword },
              uid: { type: :keyword },
              proxyIdentifiers: { type: :keyword },
              datePublished: {
                type: :date,
                format: "date_optional_time||yyyy-MM-dd||yyyy-MM||yyyy",
                ignore_malformed: true,
              },
              registrantId: { type: :keyword },
              cache_key: { type: :keyword },
            }
    indexes :source_doi, type: :keyword
    indexes :target_doi, type: :keyword
    indexes :source_relation_type_id, type: :keyword
    indexes :target_relation_type_id, type: :keyword
    indexes :source_id, type: :keyword
    indexes :source_token, type: :keyword
    indexes :message_action, type: :keyword
    indexes :relation_type_id, type: :keyword
    indexes :registrant_id, type: :keyword
    indexes :access_method, type: :keyword
    indexes :metric_type, type: :keyword
    indexes :total, type: :integer
    indexes :license, type: :text, fields: { keyword: { type: "keyword" } }
    indexes :error_messages, type: :object
    indexes :callback, type: :text
    indexes :aasm_state, type: :keyword
    indexes :state_event, type: :keyword
    indexes :year_month, type: :keyword
    indexes :created_at, type: :date
    indexes :updated_at, type: :date
    indexes :indexed_at, type: :date
    indexes :occurred_at, type: :date
    indexes :citation_id, type: :keyword
    indexes :citation_year, type: :integer
    indexes :cache_key, type: :keyword
  end

  def as_indexed_json(_options = {})
    {
      "uuid" => uuid,
      "subj_id" => subj_id,
      "obj_id" => obj_id,
      "subj" => subj.merge(cache_key: subj_cache_key),
      "obj" => obj.merge(cache_key: obj_cache_key),
      "source_doi" => source_doi,
      "target_doi" => target_doi,
      "source_relation_type_id" => source_relation_type_id,
      "target_relation_type_id" => target_relation_type_id,
      "doi" => doi,
      "orcid" => orcid,
      "issn" => issn,
      "prefix" => prefix,
      "subtype" => subtype,
      "citation_type" => citation_type,
      "source_id" => source_id,
      "source_token" => source_token,
      "message_action" => message_action,
      "relation_type_id" => relation_type_id,
      "registrant_id" => registrant_id,
      "access_method" => access_method,
      "metric_type" => metric_type,
      "total" => total,
      "license" => license,
      "error_messages" => error_messages,
      "aasm_state" => aasm_state,
      "state_event" => state_event,
      "year_month" => year_month,
      "created_at" => created_at,
      "updated_at" => updated_at,
      "indexed_at" => indexed_at,
      "occurred_at" => occurred_at,
      "citation_id" => citation_id,
      "citation_year" => citation_year,
      "cache_key" => cache_key,
    }
  end

  def citation_id
    [subj_id, obj_id].sort.join("-")
  end

  def self.query_fields
    %w[subj_id^10 obj_id^10 source_id relation_type_id]
  end

  def self.query_aggregations
    {
      sources: { terms: { field: "source_id", size: 10, min_doc_count: 1 } },
      prefixes: { terms: { field: "prefix", size: 10, min_doc_count: 1 } },
      occurred: {
          date_histogram: {
            field: "occurred_at",
            interval: "year",
            format: "year",
            order: { _key: "desc" },
            min_doc_count: 1,
          },
          aggs: { bucket_truncate: { bucket_sort: { size: 10 } } },
      },
      created: {
        date_histogram: {
          field: "created_at",
          interval: "year",
          format: "year",
          order: { _key: "desc" },
          min_doc_count: 1,
        },
        aggs: { bucket_truncate: { bucket_sort: { size: 10 } } },
    },
      registrants: {
        terms: { field: "registrant_id", size: 10, min_doc_count: 1 },
        aggs: {
          year: {
            date_histogram: {
              field: "occurred_at",
              interval: "year",
              format: "year",
              order: { _key: "desc" },
              min_doc_count: 1,
            },
            aggs: { bucket_truncate: { bucket_sort: { size: 10 } } },
          },
        },
      },
      citation_types: {
        terms: { field: "citation_type", size: 10, min_doc_count: 1 },
        aggs: {
          year_month: {
            date_histogram: {
              field: "occurred_at",
              interval: "month",
              format: "yyyy-MM",
              order: { _key: "desc" },
              min_doc_count: 1,
            },
            aggs: { bucket_truncate: { bucket_sort: { size: 10 } } },
          },
        },
      },
      relation_types: {
        terms: { field: "relation_type_id", size: 10, min_doc_count: 1 },
        aggs: {
          year_month: {
            date_histogram: {
              field: "occurred_at",
              interval: "month",
              format: "yyyy-MM",
              order: { _key: "desc" },
              min_doc_count: 1,
            },
            aggs: { bucket_truncate: { bucket_sort: { size: 10 } } },
          },
        },
      },
    }
  end

  # return results for one or more ids
  def self.find_by_id(ids, options = {})
    ids = ids.split(",") if ids.is_a?(String)

    options[:page] ||= {}
    options[:page][:number] ||= 1
    options[:page][:size] ||= 1_000
    options[:sort] ||= { created_at: { order: "asc" } }

    __elasticsearch__.search(
      from: (options.dig(:page, :number) - 1) * options.dig(:page, :size),
      size: options.dig(:page, :size),
      sort: [options[:sort]],
      query: { terms: { uuid: ids } },
      aggregations: query_aggregations,
    )
  end

  def self.import_by_ids(options = {})
    from_id = (options[:from_id] || Event.minimum(:id)).to_i
    until_id = (options[:until_id] || Event.maximum(:id)).to_i

    # get every id between from_id and until_id
    (from_id..until_id).step(500).each do |id|
      EventImportByIdJob.perform_later(options.merge(id: id))
      unless Rails.env.test?
        Rails.logger.info "Queued importing for events with IDs starting with #{
                            id
                          }."
      end
    end
  end

  def self.import_by_id(options = {})
    return nil if options[:id].blank?

    id = options[:id].to_i
    index =
      if Rails.env.test?
        "events-test"
      elsif options[:index].present?
        options[:index]
      else
        inactive_index
      end
    errors = 0
    count = 0

    Event.where(id: id..(id + 499)).find_in_batches(
      batch_size: 500,
    ) do |events|
      response =
        Event.__elasticsearch__.client.bulk index: index,
                                            type: Event.document_type,
                                            body:
                                              events.map { |event|
                                                {
                                                  index: {
                                                    _id: event.id,
                                                    data: event.as_indexed_json,
                                                  },
                                                }
                                              }

      # log errors
      errors +=
        response["items"].map { |k, _v| k.values.first["error"] }.compact.length
      response["items"].select do |k, _v|
        k.values.first["error"].present?
      end.each { |err| Rails.logger.error "[Elasticsearch] " + err.inspect }

      count += events.length
    end

    if errors > 1
      Rails.logger.error "[Elasticsearch] #{errors} errors importing #{
                           count
                         } events with IDs #{id} - #{id + 499}."
    elsif count > 0
      Rails.logger.info "[Elasticsearch] Imported #{count} events with IDs #{
                          id
                        } - #{id + 499}."
    end
  rescue Elasticsearch::Transport::Transport::Errors::RequestEntityTooLarge,
         Faraday::ConnectionFailed,
         ActiveRecord::LockWaitTimeout => e
    Rails.logger.info "[Elasticsearch] Error #{
                        e.message
                      } importing events with IDs #{id} - #{id + 499}."

    count = 0

    Event.where(id: id..(id + 499)).find_each do |event|
      IndexJob.perform_later(event)
      count += 1
    end

    Rails.logger.info "[Elasticsearch] Imported #{count} events with IDs #{
                        id
                      } - #{id + 499}."
  end

  def self.update_crossref(options = {})
    size = (options[:size] || 1_000).to_i
    cursor = (options[:cursor] || [])

    response =
      Event.query(nil, source_id: "crossref", page: { size: 1, cursor: [] })
    Rails.logger.info "[Update] #{
                        response.results.total
                      } events for source crossref."

    # walk through results using cursor
    if response.results.total > 0
      while !response.results.empty?
        response =
          Event.query(
            nil,
            source_id: "crossref", page: { size: size, cursor: cursor },
          )
        break unless response.results.length.positive?

        Rails.logger.info "[Update] Updating #{
                            response.results.length
                          } crossref events starting with _id #{
                            response.results.to_a.first[:_id]
                          }."
        cursor = response.results.to_a.last[:sort]

        dois = response.results.map(&:subj_id).uniq
        OtherDoiJob.perform_later(dois)
      end
    end

    response.results.total
  end

  def self.update_datacite_crossref(options = {})
    update_datacite_ra(options.merge(ra: "crossref"))
  end

  def self.update_datacite_medra(options = {})
    update_datacite_ra(options.merge(ra: "medra"))
  end

  def self.update_datacite_kisti(options = {})
    update_datacite_ra(options.merge(ra: "kisti"))
  end

  def self.update_datacite_jalc(options = {})
    update_datacite_ra(options.merge(ra: "jalc"))
  end

  def self.update_datacite_op(options = {})
    update_datacite_ra(options.merge(ra: "op"))
  end

  def self.update_datacite_ra(options = {})
    size = (options[:size] || 1_000).to_i
    cursor = (options[:cursor] || [])
    ra = options[:ra] || "crossref"
    source_id = "datacite-#{ra}"

    response =
      Event.query(nil, source_id: source_id, page: { size: 1, cursor: cursor })
    Rails.logger.info "[Update] #{response.results.total} events for source #{
                        source_id
                      }."

    # walk through results using cursor

    if response.results.total > 0
      while !response.results.empty?
        response =
          Event.query(
            nil,
            source_id: source_id, page: { size: size, cursor: cursor },
          )
        break if response.results.empty?

        Rails.logger.info "[Update] Updating #{response.results.length} #{
                            source_id
                          } events starting with _id #{
                            response.results.to_a.first[:_id]
                          }."
        cursor = response.results.to_a.last[:sort]

        dois = response.results.map(&:obj_id).uniq

        # use same job for all non-DataCite dois
        OtherDoiJob.perform_later(dois, options)
      end
    end

    response.results.total
  end

  def self.update_registrant(options = {})
    size = (options[:size] || 1_000).to_i
    cursor = (options[:cursor] || [])
    # ra = options[:ra] || "crossref"
    source_id = options[:source_id] || "datacite-crossref,crossref"
    citation_type = options[:citation_type] || "Dataset-ScholarlyArticle"
    query = options[:query] || "registrant_id:*crossref.citations"

    response =
      Event.query(
        query,
        source_id: source_id,
        citation_type: citation_type,
        page: { size: 1, cursor: cursor },
      )
    Rails.logger.info "[Update] #{response.results.total} events for sources #{
                        source_id
                      }."

    # walk through results using cursor

    if response.results.total > 0
      while !response.results.empty?
        response =
          Event.query(
            query,
            source_id: source_id,
            citation_type: citation_type,
            page: { size: size, cursor: cursor },
          )
        break if response.results.empty?

        Rails.logger.info "[Update] Updating #{response.results.length} #{
                            source_id
                          } events starting with _id #{
                            response.results.to_a.first[:_id]
                          }."
        cursor = response.results.to_a.last[:sort]

        ids = response.results.map(&:uuid).uniq

        EventRegistrantUpdateJob.perform_later(ids, options)
      end
    end

    response.results.total
  end

  def self.update_datacite_orcid_auto_update(options = {})
    size = (options[:size] || 1_000).to_i
    cursor = (options[:cursor] || []).to_i

    response =
      Event.query(
        nil,
        source_id: "datacite-orcid-auto-update",
        page: { size: 1, cursor: cursor },
      )
    Rails.logger.info "[Update] #{
                        response.results.total
                      } events for source datacite-orcid-auto-update."

    # walk through results using cursor

    if response.results.total > 0
      while !response.results.empty?
        response =
          Event.query(
            nil,
            source_id: "datacite-orcid-auto-update",
            page: { size: size, cursor: cursor },
          )
        break if response.results.empty?

        Rails.logger.info "[Update] Updating #{
                            response.results.length
                          } datacite-orcid-auto-update events starting with _id #{
                            response.results.to_a.first[:_id]
                          }."
        cursor = response.results.to_a.last[:sort]

        ids = response.results.map(&:obj_id).uniq
        OrcidAutoUpdateJob.perform_later(ids, options)
      end
    end

    response.results.total
  end

  def self.import_doi(id, options = {})
    doi_id = validate_doi(id)
    return nil if doi_id.blank?

    # check whether DOI has been stored with DataCite already
    # unless we want to refresh the metadata
    doi = OtherDoi.where(doi: doi_id).first
    return nil if doi.present? && options[:refresh].blank?

    # otherwise store DOI metadata with DataCite
    # check DOI registration agency as Crossref also indexes DOIs from other RAs
    prefix = doi_id.split("/", 2).first
    ra = cached_get_doi_ra(prefix).downcase
    return nil if ra.blank? || ra == "datacite"

    meta = Bolognese::Metadata.new(input: id, from: "crossref")

    # if DOi isn't registered yet
    if meta.state == "not_found"
      Rails.logger.error "[Error saving #{ra} DOI #{doi_id}]: DOI not found"
      return nil
    end

    params = {
      "doi" => meta.doi,
      "url" => meta.url,
      "xml" => meta.datacite_xml,
      "minted" => meta.date_registered,
      "schema_version" => meta.schema_version || LAST_SCHEMA_VERSION,
      "client_id" => 0,
      "source" => "levriero",
      "agency" => ra,
      "event" => "publish",
    }

    %w[
        creators
        contributors
        titles
        publisher
        publication_year
        types
        descriptions
        container
        sizes
        formats
        version_info
        language
        dates
        identifiers
        related_identifiers
        related_items
        funding_references
        geo_locations
        rights_list
        subjects
        content_url
      ].each { |a| params[a] = meta.send(a.to_s) }

    # if we refresh the metadata
    if doi.present?
      doi.assign_attributes(params.except("doi", "client_id"))
    else
      doi = OtherDoi.new(params)
    end

    if doi.save
      Rails.logger.debug "Record for #{ra} DOI #{doi.doi}" +
        (options[:refresh] ? " updated." : " created.")
    else
      Rails.logger.error "[Error saving #{ra} DOI #{doi.doi}]: " +
        doi.errors.messages.inspect
    end

    doi
  rescue ActiveRecord::RecordNotUnique => e
    # handle race condition, no need to do anything else
    Rails.logger.debug e.message
  end

  def to_param
    uuid
  end

  # import DOIs unless they are from DataCite or are a Crossref Funder ID
  def dois_to_import
    [doi_from_url(subj_id), doi_from_url(obj_id)].compact.reduce(
      [],
    ) do |sum, d|
      prefix = d.split("/", 2).first

      # ignore Crossref Funder ID
      next sum if prefix == "10.13039"

      # ignore DataCite DOIs
      ra = cached_get_doi_ra(prefix)&.downcase
      next sum if ra.blank? || ra == "datacite"

      sum.push d
      sum
    end
  end

  def send_callback
    data = {
      "data" => {
        "id" => uuid,
        "type" => "events",
        "state" => aasm_state,
        "errors" => error_messages,
        "messageAction" => message_action,
        "sourceToken" => source_token,
        "total" => total,
        "timestamp" => timestamp,
      },
    }
    Maremma.post(callback, data: data.to_json, token: ENV["API_KEY"])
  end

  def access_method
    if /(requests|investigations)/.match?(relation_type_id.to_s)
      relation_type_id.split("-").last if relation_type_id.present?
    end
  end

  def self.subj_id_check(options = {})
    size = (options[:size] || 1_000).to_i
    cursor = [options[:from_id], options[:until_id]]

    response =
      Event.query(
        nil,
        source_id: "datacite-crossref", page: { size: 1, cursor: [] },
      )
    Rails.logger.warn "[DoubleCheck] #{
                        response.results.total
                      } events for source datacite-crossref."

    # walk through results using cursor
    if response.results.total.positive?
      while response.results.length.positive?
        response =
          Event.query(
            nil,
            source_id: "datacite-crossref",
            page: { size: size, cursor: cursor },
          )
        break unless response.results.length.positive?

        Rails.logger.warn "[DoubleCheck] DoubleCheck #{
                            response.results.length
                          }  events starting with _id #{
                            response.results.to_a.first[:_id]
                          }."
        cursor = response.results.to_a.last[:sort]
        Rails.logger.warn "[DoubleCheck] Cursor: #{cursor} "

        events =
          response.results.map do |item|
            { uuid: item.uuid, subj_id: item.subj_id }
          end
        SubjCheckJob.perform_later(events, options)
      end
    end
  end

  def self.modify_nested_objects(options = {})
    size = (options[:size] || 1_000).to_i
    cursor = [options[:from_id], options[:until_id]]

    response = Event.query(nil, page: { size: 1, cursor: [] })
    Rails.logger.info "[modify_nested_objects] #{
                        response.results.total
                      } events for source datacite-crossref."

    # walk through results using cursor
    if response.results.total.positive?
      while response.results.length.positive?
        response = Event.query(nil, page: { size: size, cursor: cursor })
        break unless response.results.length.positive?

        Rails.logger.info "[modify_nested_objects] modify_nested_objects #{
                            response.results.length
                          }  events starting with _id #{
                            response.results.to_a.first[:_id]
                          }."
        cursor = response.results.to_a.last[:sort]
        Rails.logger.info "[modify_nested_objects] Cursor: #{cursor} "

        ids = response.results.map(&:uuid).uniq
        ids.each do |id|
          CamelcaseNestedObjectsByIdJob.perform_later(id, options)
        end
      end
    end
  end

  def self.camelcase_nested_objects(uuid)
    event = Event.find_by(uuid: uuid)
    if event.present?
      subj =
        event.subj.transform_keys do |key|
          key.to_s.underscore.camelcase(:lower)
        end
      obj =
        event.obj.transform_keys { |key| key.to_s.underscore.camelcase(:lower) }
      event.update(subj: subj, obj: obj)
    end
  end

  def self.label_state_event(event)
    subj_prefix = event[:subj_id][/(10\.\d{4,5})/, 1]
    unless Prefix.where(uid: subj_prefix).exists?
      Event.find_by(uuid: event[:uuid]).update_attribute(
        :state_event,
        "crossref_citations_error",
      )
    end
  end

  # Transverses the index in batches and using the cursor pagination and executes a Job that matches the query and filter
  # Options:
  # +filter+:: paramaters to filter the index
  # +label+:: String to output in the logs printout
  # +query+:: ES query to filter the index
  # +job_name+:: Acive Job class name of the Job that would be executed on every matched results
  def self.loop_through_events(options)
    size = (options[:size] || 1_000).to_i
    cursor = options[:cursor] || []
    filter = options[:filter] || {}
    label = options[:label] || ""
    job_name = options[:job_name] || ""
    query = options[:query].presence

    response = Event.query(query, filter.merge(page: { size: 1, cursor: [] }))

    if response.size.positive?
      while response.size.positive?
        response = Event.query(query, filter.merge(page: { size: size, cursor: cursor }))

        break unless response.size.positive?

        Rails.logger.info("#{label}: #{response.size} events starting with _id #{response.results.to_a.first[:_id]}")

        cursor = response.results.to_a.last[:sort]

        Rails.logger.info "#{label}: cursor: #{cursor}"

        ids = response.results.map(&:uuid).uniq

        ids.each do |id|
          Object.const_get(job_name).perform_later(id, options)
        end
      end
    end

    Rails.logger.info("#{label}: task completed")
  end

  def metric_type
    if /(requests|investigations)/.match?(relation_type_id.to_s)
      arr = relation_type_id.split("-", 4)
      arr[0..2].join("-")
    end
  end

  def doi
    Array.wrap(subj["proxyIdentifiers"]).grep(%r{\A10\.\d{4,5}/.+\z}) { $1 } +
      Array.wrap(obj["proxyIdentifiers"]).grep(%r{\A10\.\d{4,5}/.+\z}) { $1 } +
      Array.wrap(subj["funder"]).map { |f| doi_from_url(f["@id"]) }.compact +
      Array.wrap(obj["funder"]).map { |f| doi_from_url(f["@id"]) }.compact +
      [doi_from_url(subj_id), doi_from_url(obj_id)].compact
  end

  def prefix
    [doi.map { |d| d.to_s.split("/", 2).first }].compact
  end

  def orcid
    Array.wrap(subj["author"]).map { |f| orcid_from_url(f["@id"]) }.compact +
      Array.wrap(obj["author"]).map { |f| orcid_from_url(f["@id"]) }.compact +
      [orcid_from_url(subj_id), orcid_from_url(obj_id)].compact
  end

  def issn
    Array.wrap(subj.dig("periodical", "issn")).compact +
      Array.wrap(obj.dig("periodical", "issn")).compact
  rescue TypeError
    nil
  end

  def uuid_format
    errors.add(:uuid, "#{uuid} is not a valid UUID") unless UUID.validate(uuid)
  end

  def registrant_id
    [
      subj["registrantId"],
      obj["registrantId"],
      subj["providerId"],
      obj["providerId"],
    ].compact
  end

  def subtype
    [subj["@type"], obj["@type"]].compact
  end

  def citation_type
    if subj["@type"].blank? || subj["@type"] == "CreativeWork" ||
        obj["@type"].blank? ||
        obj["@type"] == "CreativeWork"
      return nil
    end

    [subj["@type"], obj["@type"]].compact.sort.join("-")
  end

  def uppercase_doi_from_url(url)
    if %r{\A(?:(http|https)://(dx\.)?(doi.org|handle.test.datacite.org)/)?(doi:)?(10\.\d{4,5}/.+)\z}.
        match?(url)
      uri = Addressable::URI.parse(url)
      uri.path.gsub(%r{^/}, "").upcase
    end
  end

  def orcid_from_url(url)
    Array(%r{\A(http|https)://orcid\.org/(.+)}.match(url)).last
  end

  def timestamp
    updated_at.utc.iso8601 if updated_at.present?
  end

  def year_month
    occurred_at.utc.iso8601[0..6] if occurred_at.present?
  end

  def cache_key
    timestamp = updated_at || Time.zone.now
    "events/#{uuid}-#{timestamp.iso8601}"
  end

  def subj_cache_key
    timestamp = subj["dateModified"] || Time.zone.now.iso8601
    "objects/#{subj_id}-#{timestamp}"
  end

  def obj_cache_key
    timestamp = obj["dateModified"] || Time.zone.now.iso8601
    "objects/#{obj_id}-#{timestamp}"
  end

  def citation_year
    unless (INCLUDED_RELATION_TYPES + RELATIONS_RELATION_TYPES).include?(
      relation_type_id,
    )
      ""
    end
    subj_publication =
      subj["datePublished"] || subj["date_published"] ||
      (date_published(subj_id) || year_month)
    obj_publication =
      obj["datePublished"] || obj["date_published"] ||
      (date_published(obj_id) || year_month)
    [subj_publication[0..3].to_i, obj_publication[0..3].to_i].max
  end

  def date_published(doi)
    ## TODO: we need to make sure all the dois from other RA are indexed
    item = Doi.where(doi: uppercase_doi_from_url(doi)).first
    item[:publication_year].to_s if item.present?
  end

  def set_source_and_target_doi
    return nil unless subj_id && obj_id

    case relation_type_id
    when *REFERENCE_RELATION_TYPES
      self.source_doi = uppercase_doi_from_url(subj_id)
      self.target_doi = uppercase_doi_from_url(obj_id)
      self.source_relation_type_id = "references"
      self.target_relation_type_id = "citations"
    when *CITATION_RELATION_TYPES
      self.source_doi = uppercase_doi_from_url(obj_id)
      self.target_doi = uppercase_doi_from_url(subj_id)
      self.source_relation_type_id = "references"
      self.target_relation_type_id = "citations"
    when "unique-dataset-investigations-regular"
      self.target_doi = uppercase_doi_from_url(obj_id)
      self.target_relation_type_id = "views"
    when "unique-dataset-requests-regular"
      self.target_doi = uppercase_doi_from_url(obj_id)
      self.target_relation_type_id = "downloads"
    when "has-version"
      self.source_doi = uppercase_doi_from_url(subj_id)
      self.target_doi = uppercase_doi_from_url(obj_id)
      self.source_relation_type_id = "versions"
      self.target_relation_type_id = "version_of"
    when "is-version-of"
      self.source_doi = uppercase_doi_from_url(obj_id)
      self.target_doi = uppercase_doi_from_url(subj_id)
      self.source_relation_type_id = "versions"
      self.target_relation_type_id = "version_of"
    when "has-part"
      self.source_doi = uppercase_doi_from_url(subj_id)
      self.target_doi = uppercase_doi_from_url(obj_id)
      self.source_relation_type_id = "parts"
      self.target_relation_type_id = "part_of"
    when "is-part-of"
      self.source_doi = uppercase_doi_from_url(obj_id)
      self.target_doi = uppercase_doi_from_url(subj_id)
      self.source_relation_type_id = "parts"
      self.target_relation_type_id = "part_of"
    end
  end

  def set_defaults
    self.uuid = SecureRandom.uuid if uuid.blank?
    self.subj_id = normalize_doi(subj_id) || subj_id
    self.obj_id = normalize_doi(obj_id) || obj_id

    # make sure subj and obj have correct id
    self.subj = subj.to_h.merge("id" => subj_id)
    self.obj = obj.to_h.merge("id" => obj_id)

    ### makes keys camel case to match JSONAPI
    subj.transform_keys! { |key| key.to_s.underscore.camelcase(:lower) }
    obj.transform_keys! { |key| key.to_s.underscore.camelcase(:lower) }

    self.total = 1 if total.blank?
    self.relation_type_id = "references" if relation_type_id.blank?
    self.occurred_at = Time.zone.now.utc if occurred_at.blank?
    if license.blank?
      self.license = "https://creativecommons.org/publicdomain/zero/1.0/"
    end
  end # overridden, use uuid instead of id

  def self.events_involving(_doi, relation_types = ALL_RELATION_TYPES)
    Enumerator.new do |yielder|
      all_results = []
      page_number = 1
      page_size = 500


      initial_results = self.query(
        nil,
        doi: _doi,
        source_id: RELATED_SOURCE_IDS.join(","),
        relation_type_id: relation_types.join(","),
        page: { size: page_size, number: page_number },
      ).results

      total_results = initial_results.total
      total_pages = page_size > 0 ? (total_results.to_f / page_size).ceil : 0
      all_results.concat(initial_results.results)
      initial_results.results.each do |event|
        yielder.yield(event)
      end

      # Explicitly Loop through remaining pages and concat to all_results
      if total_pages > 1
        (2..total_pages).each do |page_num|
          results = self.query(
            nil,
            doi: _doi,
            source_id: RELATED_SOURCE_IDS.join(","),
            relation_type_id: relation_types.join(","),
            page: { size: page_size, number: page_num },
          ).results
          results.results.each do |event|
            yielder.yield(event)
          end
        end
      end
    end
  end
end
