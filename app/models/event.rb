class Event < ActiveRecord::Base
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

  before_validation :set_defaults

  validates :uuid, format: { with: /\A[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/i }

  # include state machine
  include AASM

  aasm :whiny_transitions => false do
    state :waiting, :initial => true
    state :working, :failed, :done

    # Reset after failure
    event :reset do
      transitions from: [:failed], to: :waiting
    end

    event :start do
      transitions from: [:waiting], to: :working
    end

    event :finish do
      transitions from: [:working], to: :done
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

  serialize :subj, JSON
  serialize :obj, JSON
  serialize :error_messages, JSON

  alias_attribute :created, :created_at
  alias_attribute :updated, :updated_at

  INCLUDED_RELATION_TYPES = [
    "cites", "is-cited-by",
    "compiles", "is-compiled-by",
    "documents", "is-documented-by",
    "has-metadata", "is-metadata-for",
    "is-supplement-to", "is-supplemented-by",
    "is-derived-from", "is-source-of",
    "references", "is-referenced-by",
    "reviews", "is-reviewed-by",
    "requires", "is-required-by",
    "describes", "is-described-by"
  ]

  VIEWS_RELATION_TYPES = [
    "unique-dataset-investigations-regular"
  ]
  
  DOWNLOADS_RELATION_TYPES = [
    "unique-dataset-requests-regular"
  ]

  validates :subj_id, :source_id, :source_token, presence: true

  attr_accessor :container_title, :url

  # use different index for testing
  index_name Rails.env.test? ? "events-test" : "events"

  mapping dynamic: "false" do
    indexes :uuid,             type: :keyword
    indexes :subj_id,          type: :keyword
    indexes :obj_id,           type: :keyword
    indexes :doi,              type: :keyword
    indexes :orcid,            type: :keyword
    indexes :prefix,           type: :keyword
    indexes :subtype,          type: :keyword
    indexes :citation_type,    type: :keyword
    indexes :issn,             type: :keyword
    indexes :subj,             type: :object, properties: {
      type: { type: :keyword },
      id: { type: :keyword },
      uid: { type: :keyword },
      proxyIdentifiers: { type: :keyword },
      datePublished: { type: :date, format: "date_optional_time||yyyy-MM-dd||yyyy-MM||yyyy", ignore_malformed: true },
      registrantId: { type: :keyword },
      cache_key: { type: :keyword }
    }
    indexes :obj,               type: :object, properties: {
      type: { type: :keyword },
      id: { type: :keyword },
      uid: { type: :keyword },
      proxyIdentifiers: { type: :keyword },
      datePublished: { type: :date, format: "date_optional_time||yyyy-MM-dd||yyyy-MM||yyyy", ignore_malformed: true },
      registrantId: { type: :keyword },
      cache_key: { type: :keyword }
    }
    indexes :source_id,        type: :keyword
    indexes :source_token,     type: :keyword
    indexes :message_action,   type: :keyword
    indexes :relation_type_id, type: :keyword
    indexes :registrant_id,    type: :keyword
    indexes :access_method,    type: :keyword
    indexes :metric_type,      type: :keyword
    indexes :total,            type: :integer
    indexes :license,          type: :text, fields: { keyword: { type: "keyword" }}
    indexes :error_messages,   type: :object
    indexes :callback,         type: :text
    indexes :aasm_state,       type: :keyword
    indexes :state_event,      type: :keyword
    indexes :year_month,       type: :keyword
    indexes :created_at,       type: :date
    indexes :updated_at,       type: :date
    indexes :indexed_at,       type: :date
    indexes :occurred_at,      type: :date
    indexes :citation_id,      type: :keyword
    indexes :citation_year,    type: :integer
    indexes :cache_key,        type: :keyword
  end

  def as_indexed_json(options={})
    {
      "uuid" => uuid,
      "subj_id" => subj_id,
      "obj_id" => obj_id,
      "subj" => subj.merge(cache_key: subj_cache_key),
      "obj" => obj.merge(cache_key: obj_cache_key),
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
      "cache_key" => cache_key
    }
  end

  def citation_id
    [subj_id, obj_id].sort.join("-")
  end

  def self.query_fields
    ['subj_id^10', 'obj_id^10', 'subj.name^5', 'subj.author^5', 'subj.periodical^5', 'subj.publisher^5', 'obj.name^5', 'obj.author^5', 'obj.periodical^5', 'obj.publisher^5', '_all']
  end

  def self.query_aggregations
    sum_distribution = {
      sum_bucket: {
        buckets_path: "year_months>total_by_year_month"
      }
    }

    sum_year_distribution = {
      sum_bucket: {
        buckets_path: "years>total_by_year"
      }
    }

    {
      sources: { terms: { field: 'source_id', size: 50, min_doc_count: 1 } },
      prefixes: { terms: { field: 'prefix', size: 50, min_doc_count: 1 } },
      registrants: { terms: { field: 'registrant_id', size: 50, min_doc_count: 1 }, aggs: { year: { date_histogram: { field: 'occurred_at', interval: 'year', min_doc_count: 1 }, aggs: { "total_by_year" => { sum: { field: 'total' }}}}} },
      pairings: { terms: { field: 'registrant_id', size: 50, min_doc_count: 1 }, aggs: { recipient: { terms: { field: 'registrant_id', size: 50, min_doc_count: 1 }, aggs: { "total" => { sum: { field: 'total' }}}}} },
      citation_types: { terms: { field: 'citation_type', size: 50, min_doc_count: 1 }, aggs: { year_months: { date_histogram: { field: 'occurred_at', interval: 'month', min_doc_count: 1 }, aggs: { "total_by_year_month" => { sum: { field: 'total' }}}}} },
      relation_types: { terms: { field: 'relation_type_id', size: 50, min_doc_count: 1 }, aggs: { year_months: { date_histogram: { field: 'occurred_at', interval: 'month', min_doc_count: 1 }, aggs: { "total_by_year_month" => { sum: { field: 'total' }}}},"sum_distribution"=>sum_distribution} },
      dois: { terms: { field: 'obj_id', size: 50, min_doc_count: 1 }, aggs: { relation_types: { terms: { field: 'relation_type_id',size: 50, min_doc_count: 1 }, aggs: { "total_by_type" => { sum: { field: 'total' }}}}} },
      dois_usage: {
        filter: { script: { script: "doc['source_id'].value == 'datacite-usage' && doc['occurred_at'].value.getMillis() >= doc['obj.datePublished'].value.getMillis() && doc['occurred_at'].value.getMillis() < new Date().getTime()" }},
        aggs: {
          dois: { terms: { field: 'obj_id', size: 50, min_doc_count: 1 }, aggs: { relation_types: { terms: { field: 'relation_type_id',size: 50, min_doc_count: 1 }, aggs: { "total_by_type" => { sum: { field: 'total' }}}}} } }
      },
      dois_citations: {
        filter: {
          script: {
            script: "#{INCLUDED_RELATION_TYPES}.contains(doc['relation_type_id'].value)"
          }
        },
        aggs: { years: { date_histogram: { field: 'occurred_at', interval: 'year', min_doc_count: 1 }, aggs: { "total_by_year" => { sum: { field: 'total' }}}},"sum_distribution"=>sum_year_distribution}
      }
    }
  end

  def self.metrics_aggregations
    sum_distribution = {
      sum_bucket: {
        buckets_path: "year_months>total_by_year_month"
      }
    }
    sum_year_distribution = {
      sum_bucket: {
        buckets_path: "years>total_by_year"
      }
    }

    views_filter = {script: {script: "#{VIEWS_RELATION_TYPES}.contains(doc['relation_type_id'].value) && doc['source_id'].value == 'datacite-usage' && doc['occurred_at'].value.getMillis() >= doc['obj.datePublished'].value.getMillis() && doc['occurred_at'].value.getMillis() < new Date().getTime()"}}

    downloads_filter = {script: {script: "#{DOWNLOADS_RELATION_TYPES}.contains(doc['relation_type_id'].value) && doc['source_id'].value == 'datacite-usage' && doc['occurred_at'].value.getMillis() >= doc['obj.datePublished'].value.getMillis() && doc['occurred_at'].value.getMillis() < new Date().getTime()"} }

    {
      citations_histogram: {
        filter: {script: {script: "#{INCLUDED_RELATION_TYPES}.contains(doc['relation_type_id'].value)"}
        },
        aggs: { years: { histogram: { field: 'citation_year', interval: 1 , min_doc_count: 1 }, aggs: { "total_by_year" => { sum: { field: 'total' }}}},"sum_distribution"=>sum_year_distribution}
      },
      citations: {
        filter: {script: {script: "#{INCLUDED_RELATION_TYPES}.contains(doc['relation_type_id'].value)"}
        },
        aggs: { dois: {
           terms: { field: 'doi', size: 100, min_doc_count: 1 }, aggs: { unique_citations: { cardinality: { field: 'citation_id' }}}
        }}
      },
      views: {
        filter: views_filter,
        aggs: { dois: {
          terms: { field: 'obj_id', size: 50, min_doc_count: 1 }
        }}
      },
      views_histogram: {
        filter: views_filter,
        aggs: {
          year_months: { date_histogram: { field: 'occurred_at', interval: 'month', min_doc_count: 1 }, aggs: { "total_by_year_month" => { sum: { field: 'total' } } } }, "sum_distribution" => sum_distribution
          }
        },
      downloads: {
          filter: downloads_filter,
          aggs: { dois: {
            terms: { field: 'obj_id', size: 50, min_doc_count: 1 }
          }}
        },
      downloads_histogram: {
        filter: downloads_filter,
        aggs: {
          year_months: { date_histogram: { field: 'occurred_at', interval: 'month', min_doc_count: 1 }, aggs: { "total_by_year_month" => { sum: { field: 'total' } } } }, "sum_distribution" => sum_distribution
          }
      }   
  }
  end

  # return results for one or more ids
  def self.find_by_id(ids, options={})
    ids = ids.split(",") if ids.is_a?(String)

    options[:page] ||= {}
    options[:page][:number] ||= 1
    options[:page][:size] ||= 1000
    options[:sort] ||= { created_at: { order: "asc" }}

    __elasticsearch__.search({
      from: (options.dig(:page, :number) - 1) * options.dig(:page, :size),
      size: options.dig(:page, :size),
      sort: [options[:sort]],
      query: {
        terms: {
          uuid: ids
        }
      },
      aggregations: query_aggregations
    })
  end

  def self.import_by_ids(options={})
    from_id = (options[:from_id] || Event.minimum(:id)).to_i
    until_id = (options[:until_id] || Event.maximum(:id)).to_i

    # get every id between from_id and until_id
    (from_id..until_id).step(500).each do |id|
      EventImportByIdJob.perform_later(id: id)
      puts "Queued importing for events with IDs starting with #{id}." unless Rails.env.test?
    end
  end

  def self.import_by_id(options={})
    return nil unless options[:id].present?

    id = options[:id].to_i
    index = Rails.env.test? ? "events-test" : self.inactive_index
    errors = 0
    count = 0

    logger = Logger.new(STDOUT)

    Event.where(id: id..(id + 499)).find_in_batches(batch_size: 500) do |events|
      response = Event.__elasticsearch__.client.bulk \
        index:   index,
        type:    Event.document_type,
        body:    events.map { |event| { index: { _id: event.id, data: event.as_indexed_json } } }

      # log errors
      errors += response['items'].map { |k, v| k.values.first['error'] }.compact.length
      response['items'].select { |k, v| k.values.first['error'].present? }.each do |err|
        logger.error "[Elasticsearch] " + err.inspect
      end

      count += events.length
    end

    if errors > 1
      logger.error "[Elasticsearch] #{errors} errors importing #{count} events with IDs #{id} - #{(id + 499)}."
    elsif count > 0
      logger.info "[Elasticsearch] Imported #{count} events with IDs #{id} - #{(id + 499)}."
    end
  rescue Elasticsearch::Transport::Transport::Errors::RequestEntityTooLarge, Faraday::ConnectionFailed, ActiveRecord::LockWaitTimeout => error
    logger.info "[Elasticsearch] Error #{error.message} importing events with IDs #{id} - #{(id + 499)}."

    count = 0

    Event.where(id: id..(id + 499)).find_each do |event|
      IndexJob.perform_later(event)
      count += 1
    end

    logger.info "[Elasticsearch] Imported #{count} events with IDs #{id} - #{(id + 499)}."
  end

  def self.update_crossref(options={})
    logger = Logger.new(STDOUT)

    size = (options[:size] || 1000).to_i
    cursor = [(options[:cursor] || [])]

    response = Event.query(nil, source_id: "crossref", page: { size: 1, cursor: [] })
    logger.info "[Update] #{response.results.total} events for source crossref."

    # walk through results using cursor
    if response.results.total > 0
      while response.results.results.length > 0 do
        response = Event.query(nil, source_id: "crossref", page: { size: size, cursor: cursor })
        break unless response.results.results.length > 0

        logger.info "[Update] Updating #{response.results.results.length} crossref events starting with _id #{response.results.to_a.first[:_id]}."
        cursor = response.results.to_a.last[:sort]

        dois = response.results.results.map(&:subj_id).uniq
        CrossrefDoiJob.perform_later(dois)
      end
    end

    response.results.total
  end

  def self.update_datacite_crossref(options={})
    update_datacite_ra(options.merge(ra: "crossref"))
  end

  def self.update_datacite_medra(options={})
    update_datacite_ra(options.merge(ra: "medra"))
  end

  def self.update_datacite_kisti(options={})
    update_datacite_ra(options.merge(ra: "kisti"))
  end

  def self.update_datacite_jalc(options={})
    update_datacite_ra(options.merge(ra: "jalc"))
  end

  def self.update_datacite_op(options={})
    update_datacite_ra(options.merge(ra: "op"))
  end

  def self.update_datacite_medra(options={})
    update_datacite_ra(options.merge(ra: "medra"))
  end

  def self.update_datacite_medra(options={})
    update_datacite_ra(options.merge(ra: "medra"))
  end

  def self.update_datacite_medra(options={})
    update_datacite_ra(options.merge(ra: "medra"))
  end

  def self.update_datacite_ra(options={})
    logger = Logger.new(STDOUT)

    size = (options[:size] || 1000).to_i
    cursor = (options[:cursor] || [])
    ra = options[:ra] || "crossref"
    source_id = "datacite-#{ra}"

    response = Event.query(nil, source_id: source_id, page: { size: 1, cursor: cursor })
    logger.info "[Update] #{response.results.total} events for source #{source_id}."

    # walk through results using cursor
    if response.results.total > 0
      while response.results.results.length > 0 do
        response = Event.query(nil, source_id: source_id, page: { size: size, cursor: cursor })
        break unless response.results.results.length > 0

        logger.info "[Update] Updating #{response.results.results.length} #{source_id} events starting with _id #{response.results.to_a.first[:_id]}."
        cursor = response.results.to_a.last[:sort]

        dois = response.results.results.map(&:obj_id).uniq

        # use same jobs as for crossref dois
        CrossrefDoiJob.perform_later(dois, options)
      end
    end

    response.results.total
  end

  def self.update_datacite_orcid_auto_update(options={})
    logger = Logger.new(STDOUT)

    size = (options[:size] || 1000).to_i
    cursor = (options[:cursor] || []).to_i

    response = Event.query(nil, source_id: "datacite-orcid-auto-update", page: { size: 1, cursor: cursor })
    logger.info "[Update] #{response.results.total} events for source datacite-orcid-auto-update."

    # walk through results using cursor
    if response.results.total > 0
      while response.results.results.length > 0 do
        response = Event.query(nil, source_id: "datacite-orcid-auto-update", page: { size: size, cursor: cursor })
        break unless response.results.results.length > 0

        logger.info "[Update] Updating #{response.results.results.length} datacite-orcid-auto-update events starting with _id #{response.results.to_a.first[:_id]}."
        cursor = response.results.to_a.last[:sort].first.to_i

        ids = response.results.results.map(&:obj_id).uniq
        OrcidAutoUpdateJob.perform_later(ids, options)
      end
    end

    response.results.total
  end

  def to_param  # overridden, use uuid instead of id
    uuid
  end

  def send_callback
    data = { "data" => {
               "id" => uuid,
               "type" => "events",
               "state" => aasm_state,
               "errors" => error_messages,
               "messageAction" => message_action,
               "sourceToken" => source_token,
               "total" => total,
               "timestamp" => timestamp }}
    Maremma.post(callback, data: data.to_json, token: ENV['API_KEY'])
  end

  def access_method
    if relation_type_id.to_s =~ /(requests|investigations)/
      relation_type_id.split("-").last if relation_type_id.present?
    end
  end

  def metric_type
    if relation_type_id.to_s =~ /(requests|investigations)/
      arr = relation_type_id.split("-", 4)
      arr[0..2].join("-")
    end
  end

  def doi
    Array.wrap(subj["proxyIdentifiers"]).grep(/\A10\.\d{4,5}\/.+\z/) { $1 } +
    Array.wrap(obj["proxyIdentifiers"]).grep(/\A10\.\d{4,5}\/.+\z/) { $1 } +
    Array.wrap(subj["funder"]).map { |f| doi_from_url(f["@id"]) }.compact +
    Array.wrap(obj["funder"]).map { |f| doi_from_url(f["@id"]) }.compact +
    [doi_from_url(subj_id), doi_from_url(obj_id)].compact
  end

  def prefix
    [doi.map { |d| d.to_s.split('/', 2).first }].compact
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

  def registrant_id
    [subj["registrant_id"], obj["registrant_id"], subj["provider_id"], obj["provider_id"]].compact
  end

  def subtype
    [subj["@type"], obj["@type"]].compact
  end

  def citation_type
    return nil if subj["@type"].blank? || subj["@type"] == "CreativeWork" || obj["@type"].blank? || obj["@type"] == "CreativeWork"

   [subj["@type"], obj["@type"]].compact.sort.join("-")
  end

  def doi_from_url(url)
    if /\A(?:(http|https):\/\/(dx\.)?(doi.org|handle.test.datacite.org)\/)?(doi:)?(10\.\d{4,5}\/.+)\z/.match(url)
      uri = Addressable::URI.parse(url)
      uri.path.gsub(/^\//, '').downcase
    end
  end

  def orcid_from_url(url)
    Array(/\A(http|https):\/\/orcid\.org\/(.+)/.match(url)).last
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
    "" unless INCLUDED_RELATION_TYPES.include?(relation_type_id)
    subj_publication = subj['date_published'] || (date_published(subj_id) || year_month)
    obj_publication =  obj['date_published']  || (date_published(obj_id) || year_month)
    [subj_publication[0..3].to_i, obj_publication[0..3].to_i].max
  end

  def date_published(doi)
    ## TODO: we need to make sure all the dois from other RA are indexed 
    doi = Doi.where(doi: doi).first
    doi[:published] if doi.present? 
  end

  def set_defaults
    self.uuid = SecureRandom.uuid if uuid.blank?
    self.subj_id = normalize_doi(subj_id) || subj_id
    self.obj_id = normalize_doi(obj_id) || obj_id

    # make sure subj and obj have correct id
    self.subj = subj.to_h.merge("id" => self.subj_id)
    self.obj = obj.to_h.merge("id" => self.obj_id)

    self.total = 1 if total.blank?
    self.relation_type_id = "references" if relation_type_id.blank?
    self.occurred_at = Time.zone.now.utc if occurred_at.blank?
    self.license = "https://creativecommons.org/publicdomain/zero/1.0/" if license.blank?
  end
end
