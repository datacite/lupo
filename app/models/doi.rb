require 'maremma'

class Doi < ActiveRecord::Base
  audited only: [:doi, :url, :creators, :contributors, :titles, :publisher, :publication_year, :types, :descriptions, :container, :sizes, :formats, :version_info, :language, :dates, :identifiers, :related_identifiers, :funding_references, :geo_locations, :rights_list, :subjects, :schema_version, :content_url, :landing_page, :aasm_state, :source, :reason]

  include Metadatable
  include Cacheable
  include Licensable
  include Dateable

  # include helper module for generating random DOI suffixes
  include Helpable

  # include helper module for converting and exposing metadata
  include Crosscitable

  # include state machine
  include AASM

  # include helper module for Elasticsearch
  include Indexable

  # include helper module for sending emails
  include Mailable

  include Elasticsearch::Model

  aasm :whiny_transitions => false do
    # draft is initial state for new DOIs.
    state :draft, :initial => true
    state :tombstoned, :registered, :findable, :flagged, :broken

    event :register do
      transitions from: [:draft], to: :registered, if: [:registerable?]
    end

    event :publish do
      transitions from: [:draft], to: :findable, if: [:registerable?]
      transitions from: :registered, to: :findable
    end

    event :hide do
      transitions from: [:findable], to: :registered
    end

    event :show do
      transitions from: [:registered], to: :findable
    end

    event :flag do
      transitions from: [:registered, :findable], to: :flagged
    end

    event :link_check do
      transitions from: [:tombstoned, :registered, :findable, :flagged], to: :broken
    end
  end

  self.table_name = "dataset"
  alias_attribute :created_at, :created
  alias_attribute :updated_at, :updated
  alias_attribute :registered, :minted
  alias_attribute :state, :aasm_state

  attr_accessor :current_user

  attribute :regenerate, :boolean, default: false
  attribute :only_validate, :boolean, default: false
  attribute :should_validate, :boolean, default: false

  belongs_to :client, foreign_key: :datacentre
  has_many :media, -> { order "created DESC" }, foreign_key: :dataset, dependent: :destroy
  has_many :metadata, -> { order "created DESC" }, foreign_key: :dataset, dependent: :destroy

  delegate :provider, to: :client

  validates_presence_of :doi
  validates_presence_of :url, if: Proc.new { |doi| doi.is_registered_or_findable? }

  # from https://www.crossref.org/blog/dois-and-matching-regular-expressions/ but using uppercase
  validates_format_of :doi, with: /\A10\.\d{4,5}\/[-\._;()\/:a-zA-Z0-9\*~\$\=]+\z/, on: :create
  validates_format_of :url, with: /\A(ftp|http|https):\/\/[\S]+/ , if: :url?, message: "URL is not valid"
  validates_uniqueness_of :doi, message: "This DOI has already been taken", unless: :only_validate
  validates :last_landing_page_status, numericality: { only_integer: true }, if: :last_landing_page_status?
  validates :xml, presence: true, xml_schema: true, if: Proc.new { |doi| doi.validatable? }

  after_commit :update_url, on: [:create, :update]
  after_commit :update_media, on: [:create, :update]

  before_validation :update_xml, if: :regenerate
  before_save :set_defaults, :save_metadata
  before_create { self.created = Time.zone.now.utc.iso8601 }

  scope :q, ->(query) { where("dataset.doi = ?", query) }

  # use different index for testing
  index_name Rails.env.test? ? "dois-test" : "dois"

  settings index: {
    analysis: {
      analyzer: {
        string_lowercase: { tokenizer: 'keyword', filter: %w(lowercase ascii_folding) }
      },
      normalizer: {
        keyword_lowercase: { type: "custom", filter: %w(lowercase) }
      },
      filter: {
        ascii_folding: { type: 'asciifolding', preserve_original: true }
      }
    }
  } do
    mapping dynamic: 'false' do
      indexes :id,                             type: :keyword
      indexes :uid,                            type: :keyword
      indexes :doi,                            type: :keyword
      indexes :identifier,                     type: :keyword
      indexes :url,                            type: :text, fields: { keyword: { type: "keyword" }}
      indexes :creators,                       type: :object, properties: {
        nameType: { type: :keyword },
        nameIdentifiers: { type: :object, properties: {
          nameIdentifier: { type: :keyword },
          nameIdentifierScheme: { type: :keyword },
          schemeUri: { type: :keyword }
        }},
        name: { type: :text },
        givenName: { type: :text },
        familyName: { type: :text },
        affiliation: { type: :object, properties: {
          name: { type: :keyword },
          affiliationIdentifier: { type: :keyword },
          affiliationIdentifierScheme: { type: :keyword },
          schemeUri: { type: :keyword }
        }},
      }
      indexes :contributors,                   type: :object, properties: {
        nameType: { type: :keyword },
        nameIdentifiers: { type: :object, properties: {
          nameIdentifier: { type: :keyword },
          nameIdentifierScheme: { type: :keyword },
          schemeUri: { type: :keyword }
        }},
        name: { type: :text },
        givenName: { type: :text },
        familyName: { type: :text },
        affiliation: { type: :object, properties: {
          name: { type: :keyword },
          affiliationIdentifier: { type: :keyword },
          affiliationIdentifierScheme: { type: :keyword },
          schemeUri: { type: :keyword }
        }},
        contributorType: { type: :keyword }
      }
      indexes :creator_names,                  type: :text
      indexes :titles,                         type: :object, properties: {
        title: { type: :text, fields: { keyword: { type: "keyword" }}},
        titleType: { type: :keyword },
        lang: { type: :keyword }
      }
      indexes :descriptions,                   type: :object, properties: {
        description: { type: :text },
        descriptionType: { type: :keyword },
        lang: { type: :keyword }
      }
      indexes :publisher,                      type: :text, fields: { keyword: { type: "keyword" }}
      indexes :publication_year,               type: :date, format: "yyyy", ignore_malformed: true
      indexes :client_id,                      type: :keyword
      indexes :provider_id,                    type: :keyword
      indexes :resource_type_id,               type: :keyword
      indexes :media_ids,                      type: :keyword
      indexes :media,                          type: :object, properties: {
        type: { type: :keyword },
        id: { type: :keyword },
        uid: { type: :keyword },
        url: { type: :text },
        media_type: { type: :keyword },
        version: { type: :keyword },
        created: { type: :date, ignore_malformed: true },
        updated: { type: :date, ignore_malformed: true }
      }
      indexes :identifiers,                    type: :object, properties: {
        identifierType: { type: :keyword },
        identifier: { type: :keyword }
      }
      indexes :related_identifiers,            type: :object, properties: {
        relatedIdentifierType: { type: :keyword },
        relatedIdentifier: { type: :keyword },
        relationType: { type: :keyword },
        relatedMetadataScheme: { type: :keyword },
        schemeUri: { type: :keyword },
        schemeType: { type: :keyword },
        resourceTypeGeneral: { type: :keyword }
      }
      indexes :types,                          type: :object, properties: {
        resourceTypeGeneral: { type: :keyword },
        resourceType: { type: :keyword },
        schemaOrg: { type: :keyword },
        bibtex: { type: :keyword },
        citeproc: { type: :keyword },
        ris: { type: :keyword }
      }
      indexes :funding_references,             type: :object, properties: {
        funderName: { type: :keyword },
        funderIdentifier: { type: :keyword },
        funderIdentifierType: { type: :keyword },
        awardNumber: { type: :keyword },
        awardUri: { type: :keyword },
        awardTitle: { type: :keyword }
      }
      indexes :dates,                          type: :object, properties: {
        date: { type: :text },
        dateType: { type: :keyword }
      }
      indexes :geo_locations,                  type: :object, properties: {
        geoLocationPoint: { type: :object },
        geoLocationBox: { type: :object },
        geoLocationPlace: { type: :keyword }
      }
      indexes :rights_list,                    type: :object, properties: {
        rights: { type: :keyword },
        rightsUri: { type: :keyword },
        lang: { type: :keyword }
      }
      indexes :subjects,                       type: :object, properties: {
        subject: { type: :keyword },
        subjectScheme: { type: :keyword },
        schemeUri: { type: :keyword },
        valueUri: { type: :keyword },
        lang: { type: :keyword }
      }
      indexes :container,                     type: :object, properties: {
        type: { type: :keyword },
        identifier: { type: :keyword },
        identifierType: { type: :keyword },
        title: { type: :keyword },
        volume: { type: :keyword },
        issue: { type: :keyword },
        firstPage: { type: :keyword },
        lastPage: { type: :keyword }
      }

      indexes :xml,                            type: :text, index: "false"
      indexes :content_url,                    type: :keyword
      indexes :version_info,                   type: :keyword
      indexes :formats,                        type: :keyword
      indexes :sizes,                          type: :keyword
      indexes :language,                       type: :keyword
      indexes :is_active,                      type: :keyword
      indexes :aasm_state,                     type: :keyword
      indexes :schema_version,                 type: :keyword
      indexes :metadata_version,               type: :keyword
      indexes :agency,                         type: :keyword
      indexes :source,                         type: :keyword
      indexes :prefix,                         type: :keyword
      indexes :suffix,                         type: :keyword
      indexes :reason,                         type: :text
      indexes :landing_page, type: :object, properties: {
        checked: { type: :date, ignore_malformed: true },
        url: { type: :text, fields: { keyword: { type: "keyword" }}},
        status: { type: :integer },
        contentType: { type: :keyword },
        error: { type: :keyword },
        redirectCount: { type: :integer },
        redirectUrls: { type: :keyword },
        downloadLatency: { type: :scaled_float, scaling_factor: 100 },
        hasSchemaOrg: { type: :boolean },
        schemaOrgId: { type: :keyword },
        dcIdentifier: { type: :keyword },
        citationDoi: { type: :keyword },
        bodyHasPid: { type: :boolean }
      }
      indexes :cache_key,                      type: :keyword
      indexes :registered,                     type: :date, ignore_malformed: true
      indexes :published,                      type: :date, ignore_malformed: true
      indexes :created,                        type: :date, ignore_malformed: true
      indexes :updated,                        type: :date, ignore_malformed: true

      # include parent objects
      indexes :client,                         type: :object, properties: {
        id: { type: :keyword },
        symbol: { type: :keyword },
        provider_id: { type: :keyword },
        re3data_id: { type: :keyword },
        opendoar_id: { type: :keyword },
        prefix_ids: { type: :keyword },
        name: { type: :text, fields: { keyword: { type: "keyword" }, raw: { type: "text", analyzer: "string_lowercase", "fielddata": true }} },
        alternate_name: { type: :text, fields: { keyword: { type: "keyword" }, raw: { type: "text", analyzer: "string_lowercase", "fielddata": true }} },
        description: { type: :text },
        language: { type: :keyword },
        client_type: { type: :keyword },
        repository_type: { type: :keyword },
        certificate: { type: :keyword },
        contact_name: { type: :text },
        contact_email: { type: :text, fields: { keyword: { type: "keyword" }} },
        version: { type: :integer },
        is_active: { type: :keyword },
        domains: { type: :text },
        year: { type: :integer },
        url: { type: :text, fields: { keyword: { type: "keyword" }} },
        software: { type: :text, fields: { keyword: { type: "keyword" }, raw: { type: "text", analyzer: "string_lowercase", "fielddata": true }} },
        cache_key: { type: :keyword },
        created: { type: :date },
        updated: { type: :date },
        deleted_at: { type: :date },
        cumulative_years: { type: :integer, index: "false" }
      }
      indexes :provider,                       type: :object
      indexes :resource_type,                  type: :object
    end
  end

  def as_indexed_json(options={})
    {
      "id" => uid,
      "uid" => uid,
      "doi" => doi,
      "identifier" => identifier,
      "url" => url,
      "creators" => creators_with_affiliations,
      "contributors" => contributors_with_affiliations,
      "creator_names" => creator_names,
      "titles" => titles,
      "descriptions" => descriptions,
      "publisher" => publisher,
      "client_id" => client_id,
      "provider_id" => provider_id,
      "resource_type_id" => resource_type_id,
      "media_ids" => media_ids,
      "prefix" => prefix,
      "suffix" => suffix,
      "types" => types,
      "identifiers" => identifiers,
      "related_identifiers" => related_identifiers,
      "funding_references" => funding_references,
      "publication_year" => publication_year,
      "dates" => dates,
      "geo_locations" => geo_locations,
      "rights_list" => rights_list,
      "container" => container,
      "content_url" => content_url,
      "version_info" => version_info,
      "formats" => formats,
      "sizes" => sizes,
      "language" => language,
      "subjects" => subjects,
      "xml" => xml,
      "is_active" => is_active,
      "landing_page" => landing_page,
      "agency" => agency,
      "aasm_state" => aasm_state,
      "schema_version" => schema_version,
      "metadata_version" => metadata_version,
      "reason" => reason,
      "source" => source,
      "cache_key" => cache_key,
      "registered" => registered,
      "created" => created,
      "updated" => updated,
      "published" => published,
      "client" => client.as_indexed_json,
      "provider" => provider.as_indexed_json,
      "resource_type" => resource_type.try(:as_indexed_json),
      "media" => media.map { |m| m.try(:as_indexed_json) }
    }
  end

  def self.query_aggregations
    {
      resource_types: { terms: { field: 'types.resourceTypeGeneral', size: 15, min_doc_count: 1 } },
      states: { terms: { field: 'aasm_state', size: 15, min_doc_count: 1 } },
      years: { date_histogram: { field: 'publication_year', interval: 'year', min_doc_count: 1 } },
      created: { date_histogram: { field: 'created', interval: 'year', min_doc_count: 1 } },
      registered: { date_histogram: { field: 'registered', interval: 'year', min_doc_count: 1 } },
      providers: { terms: { field: 'provider_id', size: 15, min_doc_count: 1} },
      clients: { terms: { field: 'client_id', size: 15, min_doc_count: 1 } },
      prefixes: { terms: { field: 'prefix', size: 15, min_doc_count: 1 } },
      schema_versions: { terms: { field: 'schema_version', size: 15, min_doc_count: 1 } },
      link_checks_status: { terms: { field: 'landing_page.status', size: 15, min_doc_count: 1 } },
      link_checks_has_schema_org: { terms: { field: 'landing_page.hasSchemaOrg', size: 2, min_doc_count: 1 } },
      link_checks_schema_org_id: { value_count: { field: "landing_page.schemaOrgId" } },
      link_checks_dc_identifier: { value_count: { field: "landing_page.dcIdentifier" } },
      link_checks_citation_doi: { value_count: { field: "landing_page.citationDoi" } },
      links_checked: { value_count: { field: "landing_page.checked" } },
      sources: { terms: { field: 'source', size: 15, min_doc_count: 1 } },
      subjects: { terms: { field: 'subjects.subject', size: 15, min_doc_count: 1 } },
      certificates: { terms: { field: 'client.certificate', size: 15, min_doc_count: 1 } },
    }
  end

  def self.totals_aggregations
    {
      providers_totals: { terms: { field: 'provider_id', size: ::Provider.__elasticsearch__.count, min_doc_count: 1 }, aggs: sub_aggregations},
      clients_totals: { terms: { field: 'client_id', size: ::Client.__elasticsearch__.count, min_doc_count: 1 }, aggs: sub_aggregations },
      prefixes_totals: { terms: { field: 'prefix', size: ::Prefix.count, min_doc_count: 1 }, aggs: sub_aggregations },
    }
  end

  def self.sub_aggregations
    {
      states: { terms: { field: 'aasm_state', size: 4, min_doc_count: 1 } },
      this_month: { date_range: { field: 'created', ranges: { from: "now/M", to: "now/d" } } },
      this_year: { date_range: { field: 'created', ranges: { from: "now/y", to: "now/d" } } },
      last_year: { date_range: { field: 'created', ranges: { from: "now-1y/y", to: "now/y-1d" } } },
      two_years_ago: { date_range: { field: 'created', ranges: { from: "now-2y/y", to: "now-1y/y-1d" } } }
    }
  end

  def self.query_fields
    ['doi^10', 'uid^10', 'titles.title^3', 'creator_names^3', 'creators.name^3', 'creators.id^3', 'publisher^3', 'descriptions.description^3', 'types.resourceTypeGeneral^3', 'subjects.subject^3', 'identifiers.identifier^3', 'related_identifiers.relatedIdentifier^3', '_all']
  end

  # return results for one or more ids
  def self.find_by_id(ids, options={})
    ids = ids.split(",") if ids.is_a?(String)

    options[:page] ||= {}
    options[:page][:number] ||= 1
    options[:page][:size] ||= 1000
    options[:sort] ||= { created: { order: "asc" }}

    __elasticsearch__.search({
      from: (options.dig(:page, :number) - 1) * options.dig(:page, :size),
      size: options.dig(:page, :size),
      sort: [options[:sort]],
      query: {
        terms: {
          doi: ids.map(&:upcase)
        }
      },
      aggregations: query_aggregations
    })
  end

  def self.import_one(doi_id: nil)
    logger = Logger.new(STDOUT)

    doi = Doi.where(doi: doi_id).first
    unless doi.present?
      logger.error "[MySQL] DOI " + doi_id + " not found."
      return nil
    end

    string = doi.current_metadata.present? ? doi.clean_xml(doi.current_metadata.xml) : nil
    unless string.present?
      logger.error "[MySQL] No metadata for DOI " + doi.doi + " found: " + doi.current_metadata.inspect
      return nil
    end

    meta = doi.read_datacite(string: string, sandbox: doi.sandbox)
    attrs = %w(creators contributors titles publisher publication_year types descriptions container sizes formats language dates identifiers related_identifiers funding_references geo_locations rights_list subjects content_url).map do |a|
      [a.to_sym, meta[a]]
    end.to_h.merge(schema_version: meta["schema_version"] || "http://datacite.org/schema/kernel-4", version_info: meta["version"], xml: string)

    # update_attributes will trigger validations and Elasticsearch indexing
    doi.update_attributes(attrs)
    logger.info "[MySQL] Imported metadata for DOI " + doi.doi + "."
    doi
  rescue TypeError, NoMethodError, RuntimeError, ActiveRecord::StatementInvalid, ActiveRecord::LockWaitTimeout => error
    logger.error "[MySQL] Error importing metadata for " + doi.doi + ": " + error.message
    Raven.capture_exception(error)
    doi
  end

  def self.import_by_ids(options={})
    from_id = (options[:from_id] || Doi.minimum(:id)).to_i
    until_id = (options[:until_id] || Doi.maximum(:id)).to_i

    # get every id between from_id and end_id
    (from_id..until_id).step(500).each do |id|
      DoiImportByIdJob.perform_later(options.merge(id: id))
      puts "Queued importing for DOIs with IDs starting with #{id}." unless Rails.env.test?
    end

    (from_id..until_id).to_a.length
  end

  def self.import_by_id(options={})
    return nil unless options[:id].present?

    id = options[:id].to_i
    index = if Rails.env.test?
              "dois-test"
            elsif options[:index].present?
              options[:index]
            else
              self.inactive_index
            end
    errors = 0
    count = 0

    logger = Logger.new(STDOUT)

    Doi.where(id: id..(id + 499)).find_in_batches(batch_size: 500) do |dois|
      response = Doi.__elasticsearch__.client.bulk \
        index:   index,
        type:    Doi.document_type,
        body:    dois.map { |doi| { index: { _id: doi.id, data: doi.as_indexed_json } } }

      # log errors
      errors += response['items'].map { |k, v| k.values.first['error'] }.compact.length
      response['items'].select { |k, v| k.values.first['error'].present? }.each do |err|
        logger.error "[Elasticsearch] " + err.inspect
      end

      count += dois.length
    end

    if errors > 1
      logger.error "[Elasticsearch] #{errors} errors importing #{count} DOIs with IDs #{id} - #{(id + 499)}."
    elsif count > 0
      logger.info "[Elasticsearch] Imported #{count} DOIs with IDs #{id} - #{(id + 499)}."
    end

    count
  rescue Elasticsearch::Transport::Transport::Errors::RequestEntityTooLarge, Faraday::ConnectionFailed, ActiveRecord::LockWaitTimeout => error
    logger.info "[Elasticsearch] Error #{error.message} importing DOIs with IDs #{id} - #{(id + 499)}."

    count = 0

    Doi.where(id: id..(id + 499)).find_each do |doi|
      IndexJob.perform_later(doi)
      count += 1
    end

    logger.info "[Elasticsearch] Imported #{count} DOIs with IDs #{id} - #{(id + 499)}."

    count
  end

  def uid
    doi.downcase
  end

  def resource_type_id
    types["resourceTypeGeneral"].underscore.dasherize if types.to_h["resourceTypeGeneral"].present?
  end

  def media_ids
    media.pluck(:id).map { |m| Base32::URL.encode(m, split: 4, length: 16) }.compact
  end

  def xml_encoded
    Base64.strict_encode64(xml) if xml.present?
  rescue ArgumentError => exception
    nil
  end

  # creator name in natural order: "John Smith" instead of "Smith, John"
  def creator_names
    Array.wrap(creators).map do |a|
      if a["familyName"].present?
        [a["givenName"], a["familyName"]].join(" ")
      elsif a["name"].to_s.include?(", ")
        a["name"].split(", ", 2).reverse.join(" ")
      else
        a["name"]
      end
    end
  end

  # use newer index with old database following schema 4.3 changes
  def creators_with_affiliations
    Array.wrap(creators).map do |c|
      c["affiliation"] = { "name" => c["affiliation"] } if c["affiliation"].is_a?(String)
      c
    end
  end

  def contributors_with_affiliations
    Array.wrap(contributors).map do |c|
      c["affiliation"] = { "name" => c["affiliation"] } if c["affiliation"].is_a?(String)
      c
    end
  end

  def self.convert_affiliations(options={})
    from_id = (options[:from_id] || Doi.minimum(:id)).to_i
    until_id = (options[:until_id] || Doi.maximum(:id)).to_i

    # get every id between from_id and end_id
    (from_id..until_id).step(500).each do |id|
      DoiConvertAffiliationByIdJob.perform_later(options.merge(id: id))
      puts "Queued converting affiliations for DOIs with IDs starting with #{id}." unless Rails.env.test?
    end

    (from_id..until_id).to_a.length
  end

  def self.convert_affiliation_by_id(options={})
    return nil unless options[:id].present?

    id = options[:id].to_i
    count = 0

    logger = Logger.new(STDOUT)

    Doi.where(id: id..(id + 499)).find_each do |doi|
      should_update = false
      creators = Array.wrap(doi.creators).map do |c|
        if c["affiliation"].is_a?(String)
          c["affiliation"] = { "name" => c["affiliation"] } 
          should_update = true
        end

        c
      end
      contributors = Array.wrap(doi.contributors).map do |c|
        if c["affiliation"].is_a?(String)
          c["affiliation"] = { "name" => c["affiliation"] }
          should_update = true
        end

        c
      end

      if should_update
        Doi.non_audited_columns = [:creators, :contributors]
        doi.update_attributes(creators: creators, contributors: contributors)
        count += 1
      end
    end
        
    logger.info "[Elasticsearch] Converted affiliations for #{count} DOIs with IDs #{id} - #{(id + 499)}." if count > 0

    count
  rescue Elasticsearch::Transport::Transport::Errors::RequestEntityTooLarge, Faraday::ConnectionFailed, ActiveRecord::LockWaitTimeout => error
    logger.info "[Elasticsearch] Error #{error.message} converting affiliations for DOIs with IDs #{id} - #{(id + 499)}."
  end

  def doi=(value)
    write_attribute(:doi, value.upcase) if value.present?
  end

  def identifier
    normalize_doi(doi, sandbox: !Rails.env.production?)
  end

  def client_id
    client.symbol.downcase if client.present?
  end

  def client_id=(value)
    r = ::Client.where(symbol: value).first
    fail ActiveRecord::RecordNotFound unless r.present?

    write_attribute(:datacentre, r.id)
  end

  def provider_id
    client.provider.symbol.downcase if client.present?
  end

  def prefix
    doi.split('/', 2).first if doi.present?
  end

  def suffix
    uid.split("/", 2).last if doi.present?
  end

  def registerable?
    true # && url.present?
  end

  # def is_valid?
  #   valid? && url.present?
  # end

  def is_registered_or_findable?
    %w(registered findable).include?(aasm_state) || %w(crossref medra op).include?(provider_id)
  end

  def validatable?
    %w(registered findable).include?(aasm_state) || should_validate || only_validate
  end

  # update URL in handle system for registered and findable state
  # providers europ and ethz do their own handle registration, so fetch url from handle system instead
  def update_url
    return nil if current_user.nil? || !is_registered_or_findable?

    if %w(europ).include?(provider_id)
      UrlJob.perform_later(doi)
    else
      HandleJob.perform_later(doi)
    end
  end

  def update_media
    return nil unless content_url.present?

    media.delete_all

    Array.wrap(content_url).each do |c|
      media << Media.create(url: c, media_type: formats)
    end
  end

  # attributes to be sent to elasticsearch index
  def to_jsonapi
    attributes = {
      "doi" => doi,
      "state" => aasm_state,
      "created" => created,
      "updated" => date_updated }

    { "id" => doi, "type" => "dois", "attributes" => attributes }
  end

  def current_metadata
    metadata.order('metadata.created DESC').first
  end

  def metadata_version
    current_metadata ? current_metadata.metadata_version : 0
  end

  def current_media
    media.order('media.created DESC').first
  end

  def resource_type
    cached_resource_type_response(types["resourceTypeGeneral"].underscore.dasherize.downcase) if types.to_h["resourceTypeGeneral"].present?
  end

  def date_registered
    minted.iso8601 if minted.present?
  end

  def date_updated
    updated
  end

  def published
    get_date(dates, "issued") || publication_year.to_s
  end

  def cache_key
    timestamp = updated || Time.zone.now
    "dois/#{uid}-#{timestamp.iso8601}"
  end

  def event=(value)
    self.send(value) if %w(register publish hide show).include?(value)
  end

  # to be used after DOIs were transferred to another DOI RA
  def self.delete_dois_by_prefix(prefix, options={})
    logger = Logger.new(STDOUT)

    if prefix.blank?
      Logger.error "[Error] No prefix provided."
      return nil
    end

    # query = options[:query] || "*"
    size = (options[:size] || 1000).to_i

    response = Doi.query(nil, prefix: prefix, page: { size: 1, cursor: [] })
    logger.info "#{response.results.total} DOIs found for prefix #{prefix}."

    if prefix && response.results.total > 0
      # walk through results using cursor
      cursor = []

      while response.results.results.length > 0 do
        response = Doi.query(nil, prefix: prefix, page: { size: size, cursor: cursor })
        break unless response.results.results.length > 0

        logger.info "Deleting #{response.results.results.length} DOIs starting with _id #{response.results.to_a.first[:_id]}."
        cursor = response.results.to_a.last[:sort]

        response.results.results.each do |d|
          DeleteJob.perform_later(d.doi)
        end
      end
    end

    response.results.total
  end

  # register DOIs in the handle system that have not been registered yet
  # provider europ registers their DOIs in the handle system themselves and are ignored
  def self.set_handle
    logger = Logger.new(STDOUT)

    response = Doi.query("-registered:* +url:* -aasm_state:draft -provider_id:europ -agency:Crossref", page: { size: 1, cursor: [] })
    logger.info "#{response.results.total} DOIs found that are not registered in the Handle system."

    if response.results.total > 0
      # walk through results using cursor
      cursor = []

      while response.results.results.length > 0 do
        response = Doi.query("-registered:* +url:* -aasm_state:draft -provider_id:europ -agency:Crossref", page: { size: 1000, cursor: cursor })
        break unless response.results.results.length > 0

        logger.info "[Handle] Register #{response.results.results.length} DOIs in the handle system starting with _id #{response.results.to_a.first[:_id]}."
        cursor = response.results.to_a.last[:sort]

        response.results.results.each do |d|
          HandleJob.perform_later(d.doi)
        end
      end
    end
  end

  def self.set_url
    logger = Logger.new(STDOUT)

    response = Doi.query("-url:* (+provider_id:ethz OR -aasm_status:draft)", page: { size: 1, cursor: [] })
    logger.info "#{response.results.total} DOIs with no URL found in the database."

    if response.results.total > 0
      # walk through results using cursor
      cursor = []

      while response.results.results.length > 0 do
        response = Doi.query("-url:* (+provider_id:ethz OR -aasm_status:draft)", page: { size: 1000, cursor: cursor })
        break unless response.results.results.length > 0

        logger.info "[Handle] Update URL for #{response.results.results.length} DOIs starting with _id #{response.results.to_a.first[:_id]}."
        cursor = response.results.to_a.last[:sort]

        response.results.results.each do |d|
          UrlJob.perform_later(d.doi)
        end
      end
    end
  end

  def self.set_minted
    logger = Logger.new(STDOUT)

    response = Doi.query("provider_id:ethz AND +aasm_state:draft +url:*", page: { size: 1, cursor: [] })
    logger.info "#{response.results.total} draft DOIs from provider ETHZ found in the database."

    if response.results.total > 0
      # walk through results using cursor
      cursor = []

      while response.results.results.length > 0 do
        response = Doi.query("provider_id:ethz AND +aasm_state:draft +url:*", page: { size: 1000, cursor: cursor })
        break unless response.results.results.length > 0

        logger.info "[MySQL] Set minted for #{response.results.results.length} DOIs starting with _id #{response.results.to_a.first[:_id]}."
        cursor = response.results.to_a.last[:sort]

        response.results.results.each do |d|
          UrlJob.perform_later(d.doi)
        end
      end
    end
  end

  def self.transfer(options={})
    logger = Logger.new(STDOUT)

    if options[:client_id].blank?
      Logger.error "[Transfer] No client provided."
      return nil
    end

    if options[:target_id].blank?
      Logger.error "[Transfer] No target client provided."
      return nil
    end

    query = options[:query] || "*"
    size = (options[:size] || 1000).to_i

    response = Doi.query(nil, client_id: options[:client_id], page: { size: 1, cursor: [] })
    logger.info "[Transfer] #{response.results.total} DOIs found for client #{options[:client_id]}."

    if options[:client_id] && options[:target_id] && response.results.total > 0
      # walk through results using cursor
      cursor = []

      while response.results.results.length > 0 do
        response = Doi.query(nil, client_id: options[:client_id], page: { size: size, cursor: cursor })
        break unless response.results.results.length > 0

        logger.info "[Transfer] Transferring #{response.results.results.length} DOIs starting with _id #{response.results.to_a.first[:_id]}."
        cursor = response.results.to_a.last[:sort]

        response.results.results.each do |d|
          TransferJob.perform_later(d.doi, target_id: options[:target_id])
        end
      end
    end

    response.results.total
  end

  # save to metadata table when xml has changed
  def save_metadata
    metadata.build(doi: self, xml: xml, namespace: schema_version) if xml.present? && xml_changed?
  end

  def set_defaults
    self.is_active = (aasm_state == "findable") ? "\x01" : "\x00"
    self.version = version.present? ? version + 1 : 1
    self.updated = Time.zone.now.utc.iso8601
  end

  def self.migrate_landing_page(options={})
    logger = Logger.new(STDOUT)
    logger.info "Starting migration"

    # Handle camel casing first.
    Doi.where.not('last_landing_page_status_result' => nil).find_each do |doi|
      begin
        # First we try and fix into camel casing
        result = doi.last_landing_page_status_result
        mappings = {
          "body-has-pid" => "bodyHasPid",
          "dc-identifier" => "dcIdentifier",
          "citation-doi" => "citationDoi",
          "redirect-urls" => "redirectUrls",
          "schema-org-id" => "schemaOrgId",
          "has-schema-org" => "hasSchemaOrg",
          "redirect-count" => "redirectCount",
          "download-latency" => "downloadLatency"
        }
        result = result.map {|k, v| [mappings[k] || k, v] }.to_h
        # doi.update_columns("last_landing_page_status_result": result)

        # Do a fix of the stored download Latency
        # Sometimes was floating point precision, we dont need this
        download_latency = result['downloadLatency']
        download_latency = download_latency.nil? ? download_latency : download_latency.round

        # Try to put the checked date into ISO8601
        # If we dont have one (there was legacy reasons) then set to unix epoch
        checked = doi.last_landing_page_status_check
        checked = checked.nil? ? Time.at(0) : checked
        checked = checked.iso8601

        # Next we want to build a new landing_page result.
        landing_page = {
          "checked" => checked,
          "status" => doi.last_landing_page_status,
          "url" => doi.last_landing_page,
          "contentType" => doi.last_landing_page_content_type,
          "error" => result['error'],
          "redirectCount" => result['redirectCount'],
          "redirectUrls" => result['redirectUrls'],
          "downloadLatency" => download_latency,
          "hasSchemaOrg" => result['hasSchemaOrg'],
          "schemaOrgId" => result['schemaOrgId'],
          "dcIdentifier" => result['dcIdentifier'],
          "citationDoi" => result['citationDoi'],
          "bodyHasPid" => result['bodyHasPid'],
        }

        doi.update_columns("landing_page": landing_page)

        logger.info "Updated " + doi.doi

      rescue TypeError, NoMethodError => error
        logger.error "Error updating landing page " + doi.doi + ": " + error.message
      end
    end
  end
end
