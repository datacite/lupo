require 'maremma'

class Doi < ActiveRecord::Base
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
      # can't register test prefix
      transitions :from => [:draft], :to => :registered, :if => [:registerable?]
    end

    event :publish do
      # can't index test prefix
      transitions :from => [:draft], :to => :findable, :if => [:registerable?]
      transitions :from => :registered, :to => :findable
    end

    event :hide do
      transitions :from => [:findable], :to => :registered
    end

    event :flag do
      transitions :from => [:registered, :findable], :to => :flagged
    end

    event :link_check do
      transitions :from => [:tombstoned, :registered, :findable, :flagged], :to => :broken
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
  attribute :agency, :string, default: "DataCite"

  belongs_to :client, foreign_key: :datacentre
  has_many :media, -> { order "created DESC" }, foreign_key: :dataset, dependent: :destroy
  has_many :metadata, -> { order "created DESC" }, foreign_key: :dataset, dependent: :destroy

  delegate :provider, to: :client

  validates_presence_of :doi
  # validates_presence_of :url, if: :is_registered_or_findable?

  # from https://www.crossref.org/blog/dois-and-matching-regular-expressions/ but using uppercase
  validates_format_of :doi, :with => /\A10\.\d{4,5}\/[-\._;()\/:a-zA-Z0-9\*~\$\=]+\z/, :on => :create
  validates_format_of :url, :with => /\A(ftp|http|https):\/\/[\S]+/ , if: :url?, message: "URL is not valid"
  validates_uniqueness_of :doi, message: "This DOI has already been taken", unless: :only_validate
  validates :last_landing_page_status, numericality: { only_integer: true }, if: :last_landing_page_status?
  validates :xml, presence: true, xml_schema: true, :if => Proc.new { |doi| doi.validatable? }

  after_commit :update_url, on: [:create, :update]
  after_commit :update_media, on: [:create, :update]

  before_validation :update_xml, if: :regenerate
  before_save :set_defaults, :save_metadata
  before_create { self.created = Time.zone.now.utc.iso8601 }

  scope :q, ->(query) { where("dataset.doi = ?", query) }

  # use different index for testing
  index_name Rails.env.test? ? "dois-test" : "dois"

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
        nameIdentifierScheme: { type: :keyword }
      }},
      name: { type: :text },
      givenName: { type: :text },
      familyName: { type: :text },
      affiliation: { type: :text }
    }
    indexes :contributors,                   type: :object, properties: {
      nameType: { type: :keyword },
      nameIdentifiers: { type: :object, properties: {
        nameIdentifier: { type: :keyword },
        nameIdentifierScheme: { type: :keyword }
      }},
      name: { type: :text },
      givenName: { type: :text },
      familyName: { type: :text },
      affiliation: { type: :text },
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
      date: { type: :date, format: "yyyy-MM-dd||yyyy-MM||yyyy", ignore_malformed: true },
      dateType: { type: :keyword }
    }
    indexes :geo_locations,                  type: :object, properties: {
      geoLocationPoint: { type: :object },
      geoLocationBox: { type: :object },
      geoLocationPlace: { type: :keyword }
    }
    indexes :rights_list,                    type: :object, properties: {
      rights: { type: :keyword },
      rightsUri: { type: :keyword }
    }
    indexes :subjects,                       type: :object, properties: {
      subject: { type: :keyword },
      subjectScheme: { type: :keyword },
      schemeUri: { type: :keyword },
      valueUri: { type: :keyword }
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

    indexes :xml,                            type: :text, index: "not_analyzed"
    indexes :content_url,                    type: :keyword
    indexes :version_info,                   type: :keyword
    indexes :formats,                        type: :keyword
    indexes :sizes,                          type: :keyword
    indexes :language,                       type: :keyword
    indexes :is_active,                      type: :keyword
    indexes :aasm_state,                     type: :keyword
    indexes :schema_version,                 type: :keyword
    indexes :metadata_version,               type: :keyword
    indexes :source,                         type: :keyword
    indexes :prefix,                         type: :keyword
    indexes :suffix,                         type: :keyword
    indexes :reason,                         type: :text
    indexes :landing_page, type: :object, properties: {
      checked: { type: :date, ignore_malformed: true },
      url: { type: :text, fields: { keyword: { type: "keyword" }}},
      status: { type: :integer },
      contentType: { type: :string },
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
    indexes :created,                        type: :date, ignore_malformed: true
    indexes :updated,                        type: :date, ignore_malformed: true

    # include parent objects
    indexes :client,                         type: :object
    indexes :provider,                       type: :object
    indexes :resource_type,                  type: :object
  end

  def as_indexed_json(options={})
    {
      "id" => uid,
      "uid" => uid,
      "doi" => doi,
      "identifier" => identifier,
      "url" => url,
      "creators" => creators,
      "contributors" => contributors,
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
      "aasm_state" => aasm_state,
      "schema_version" => schema_version,
      "metadata_version" => metadata_version,
      "reason" => reason,
      "source" => source,
      "cache_key" => cache_key,
      "registered" => registered,
      "created" => created,
      "updated" => updated,
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
      providers: { terms: { field: 'provider_id', size: 15, min_doc_count: 1 } },
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
    }
  end

  def self.query_fields
    ['doi^10', 'titles.title^10', 'creator_names^10', 'creators.name^10', 'creators.id^10', 'publisher^10', 'descriptions.description^10', 'types.resourceTypeGeneral^10', 'subjects.subject^10', 'identifiers.identifier^10', 'related_identifiers.relatedIdentifier^10', '_all']
  end

  def self.find_by_id(id, options={})
    return nil unless id.present?

    __elasticsearch__.search({
      query: {
        term: {
          doi: id.downcase
        }
      },
      aggregations: query_aggregations
    })
  end

  def self.import_one(doi: nil)
    doi = Doi.where(doi: doi).first
    return nil unless doi.present?

    string = doi.current_metadata.to_s.start_with?('<?xml version=') ? doi.current_metadata.xml.force_encoding("UTF-8") : nil
    meta = doi.read_datacite(string: string, sandbox: doi.sandbox)
    attrs = %w(creators contributors titles publisher publication_year types descriptions container sizes formats language dates identifiers related_identifiers funding_references geo_locations rights_list subjects content_url).map do |a|
      [a.to_sym, meta[a]]
    end.to_h.merge(schema_version: meta["schema_version"] || "http://datacite.org/schema/kernel-4", version_info: meta["version"], xml: string)

    # update_attributes will trigger validations and Elasticsearch indexing
    doi.update_attributes(attrs)
    logger.info "[MySQL] Imported metadata for DOI  " + doi.doi + "."
  rescue TypeError, NoMethodError, RuntimeError, ActiveRecord::StatementInvalid, ActiveRecord::LockWaitTimeout => error
    logger.error "[MySQL] Error importing metadata for " + doi.doi + ": " + error.message
    Bugsnag.notify(error)
  end

  def self.import_all(options={})
    from_date = options[:from_date].present? ? Date.parse(options[:from_date]) : Date.current
    until_date = options[:until_date].present? ? Date.parse(options[:until_date]) : Date.current

    # get every day between from_date and until_date
    (from_date..until_date).each do |d|
      DoiImportByDayJob.perform_later(from_date: d.strftime("%F"))
      puts "Queued importing for DOIs created on #{d.strftime("%F")}."
    end
  end

  def self.import_missing(options={})
    from_date = options[:from_date].present? ? Date.parse(options[:from_date]) : Date.current
    until_date = options[:until_date].present? ? Date.parse(options[:until_date]) : Date.current

    # get every day between from_date and until_date
    (from_date..until_date).each do |d|
      DoiImportByDayMissingJob.perform_later(from_date: d.strftime("%F"))
      puts "Queued importing for missing DOIs created on #{d.strftime("%F")}."
    end
  end

  def self.import_by_day(options={})
    return nil unless options[:from_date].present?
    from_date = Date.parse(options[:from_date])

    count = 0

    logger = Logger.new(STDOUT)

    Doi.where(created: from_date.midnight..from_date.end_of_day).find_each do |doi|
      begin
        # ignore broken xml
        string = doi.current_metadata.to_s.start_with?('<?xml version=') ? doi.current_metadata.xml.force_encoding("UTF-8") : nil
        meta = doi.read_datacite(string: string, sandbox: doi.sandbox)
        attrs = %w(creators contributors titles publisher publication_year types descriptions container sizes formats language dates identifiers related_identifiers funding_references geo_locations rights_list subjects content_url).map do |a|
          [a.to_sym, meta[a]]
        end.to_h.merge(schema_version: meta["schema_version"] || "http://datacite.org/schema/kernel-4", version_info: meta["version"], xml: string)

        # update_columns will NOT trigger validations and Elasticsearch indexing
        doi.update_columns(attrs)
      rescue TypeError, NoMethodError, RuntimeError, ActiveRecord::StatementInvalid, ActiveRecord::LockWaitTimeout => error
        logger.error "[MySQL] Error importing metadata for " + doi.doi + ": " + error.message
        Bugsnag.notify(error)
      else
        count += 1
      end
    end

    if count > 0
      logger.info "[MySQL] Imported metadata for #{count} DOIs created on #{options[:from_date]}."
    end
  end

  def self.import_by_day_missing(options={})
    return nil unless options[:from_date].present?
    from_date = Date.parse(options[:from_date])

    count = 0

    logger = Logger.new(STDOUT)

    Doi.where(schema_version: nil).where(created: from_date.midnight..from_date.end_of_day).find_each do |doi|
      begin
        string = doi.current_metadata.to_s.start_with?('<?xml version=') ? doi.current_metadata.xml.force_encoding("UTF-8") : nil
        meta = doi.read_datacite(string: string, sandbox: doi.sandbox)
        attrs = %w(creators contributors titles publisher publication_year types descriptions container sizes formats language dates identifiers related_identifiers funding_references geo_locations rights_list subjects content_url).map do |a|
          [a.to_sym, meta[a]]
        end.to_h.merge(schema_version: meta["schema_version"] || "http://datacite.org/schema/kernel-4", version_info: meta["version"], xml: string)

        # update_columns will NOT trigger validations and Elasticsearch indexing
        doi.update_columns(attrs)
      rescue TypeError, NoMethodError, RuntimeError, ActiveRecord::StatementInvalid, ActiveRecord::LockWaitTimeout => error
        logger.error "[MySQL] Error importing metadata for " + doi.doi + ": " + error.message
        Bugsnag.notify(error)
      else
        count += 1
      end
    end

    if count > 0
      logger.info "[MySQL] Imported metadata for #{count} DOIs created on #{options[:from_date]}."
    end
  end

  def self.index(options={})
    from_date = options[:from_date].present? ? Date.parse(options[:from_date]) : Date.current
    until_date = options[:until_date].present? ? Date.parse(options[:until_date]) : Date.current
    index_time = options[:index_time].presence || Time.zone.now.utc.iso8601

    # get every day between from_date and until_date
    (from_date..until_date).each do |d|
      DoiIndexByDayJob.perform_later(from_date: d.strftime("%F"), index_time: index_time)
      puts "Queued indexing for DOIs created on #{d.strftime("%F")}."
    end
  end

  def self.index_by_day(options={})
    return nil unless options[:from_date].present?
    from_date = Date.parse(options[:from_date])
    index_time = options[:index_time].presence || Time.zone.now.utc.iso8601

    errors = 0
    count = 0

    logger = Logger.new(STDOUT)

    Doi.where(created: from_date.midnight..from_date.end_of_day).where("indexed < ?", index_time).find_in_batches(batch_size: 500) do |dois|
      response = Doi.__elasticsearch__.client.bulk \
        index:   Doi.index_name,
        type:    Doi.document_type,
        body:    dois.map { |doi| { index: { _id: doi.id, data: doi.as_indexed_json } } }

      # log errors
      errors += response['items'].map { |k, v| k.values.first['error'] }.compact.length
      response['items'].select { |k, v| k.values.first['error'].present? }.each do |err|
        logger.error "[Elasticsearch] " + err.inspect
      end

      dois.each { |doi| doi.update_column(:indexed, Time.zone.now) }
      count += dois.length
    end

    if errors > 1
      logger.error "[Elasticsearch] #{errors} errors indexing #{count} DOIs created on #{options[:from_date]}."
    elsif count > 1
      logger.info "[Elasticsearch] Indexed #{count} DOIs created on #{options[:from_date]}."
    end
  rescue Elasticsearch::Transport::Transport::Errors::RequestEntityTooLarge, Faraday::ConnectionFailed, ActiveRecord::LockWaitTimeout => error
    logger.info "[Elasticsearch] Error #{error.message} indexing DOIs created on #{options[:from_date]}."

    count = 0

    Doi.where(created: from_date.midnight..from_date.end_of_day).where("indexed < ?", index_time).find_each do |doi|
      IndexJob.perform_later(doi)
      doi.update_column(:indexed, Time.zone.now)
      count += 1
    end

    logger.info "[Elasticsearch] Indexed #{count} DOIs created on #{options[:from_date]}."
  end

  def uid
    doi.downcase
  end

  def resource_type_id
    types["resourceTypeGeneral"].underscore.dasherize if types.to_h["resourceTypeGeneral"].present?
  end

  def media_ids
    media.pluck(:id).map { |m| Base32::URL.encode(m, split: 4, length: 16) }
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
    #r = cached_client_response(value)
    fail ActiveRecord::RecordNotFound unless r.present?

    write_attribute(:datacentre, r.id)
  end

  def provider_id
    provider.symbol.downcase
  end

  def prefix
    doi.split('/', 2).first if doi.present?
  end

  def suffix
    uid.split("/", 2).last if doi.present?
  end

  def is_test_prefix?
    prefix == "10.5072"
  end

  def registerable?
    prefix != "10.5072" && url.present?
  end

  # def is_valid?
  #   valid? && url.present?
  # end

  def is_registered_or_findable?
    %w(registered findable).include?(aasm_state)
  end

  def validatable?
    %w(registered findable).include?(aasm_state) || should_validate || only_validate
  end

  # update URL in handle system for registered and findable state
  # providers europ and ethz do their own handle registration
  def update_url
    return nil if current_user.nil? || !is_registered_or_findable? || %w(europ ethz).include?(provider_id)

    HandleJob.perform_later(doi)
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
    fetch_cached_metadata_version
  end

  def current_media
    media.order('media.created DESC').first
  end

  def resource_type
    cached_resource_type_response(types["resourceTypeGeneral"].underscore.dasherize.downcase) if types.to_h["resourceTypeGeneral"].present?
  end

  def date_registered
    minted
  end

  def date_updated
    updated
  end

  def cache_key
    timestamp = updated || Time.zone.now
    "dois/#{uid}-#{timestamp.iso8601}"
  end

  def event=(value)
    self.send(value) if %w(register publish hide).include?(value)
  end

  # delete all DOIs with test prefix 10.5072 not updated since from_date
  # we need to use destroy_all to also delete has_many associations for metadata and media
  def self.delete_test_dois(from_date: nil)
    from_date ||= Time.zone.now - 1.month
    collection = Doi.where("updated < ?", from_date)
    collection.where("doi LIKE ?", "10.5072%").find_each do |d|
      logger = Logger.new(STDOUT)
      logger.info "Automatically deleted #{d.doi}, last updated #{d.updated.iso8601}."
      d.destroy
    end
  end

  # set minted date for DOIs that have been registered in an handle system (providers ETHZ and EUROP)
  def self.set_minted(from_date: nil)
    from_date ||= Time.zone.now - 1.day
    ids = ENV['HANDLES_MINTED'].to_s.split(",")
    return nil unless ids.present?

    collection = Doi.where("datacentre in (SELECT id from datacentre where allocator IN (:ids))", ids: ids).where("updated >= ?", from_date).where("updated < ?", Time.zone.now - 15.minutes)
    collection.where(is_active: "\x01").where(minted: nil).update_all(("minted = updated"))
  end

  # register DOIs in the handle system that have not been registered yet
  def self.register_all_urls(limit: nil)
    limit ||= 100

    Doi.where(minted: nil).where.not(url: nil).where.not(aasm_state: "draft").where("updated < ?", Time.zone.now - 15.minutes).order(created: :desc).limit(limit.to_i).find_each do |d|
      HandleJob.perform_later(d.doi)
    end
  end

  def self.set_url(from_date: nil)
    from_date = from_date.present? ? Date.parse(from_date) : Date.current - 1.day
    Doi.where(url: nil).where.not(minted: nil).where("updated >= ?", from_date).find_each do |doi|
      UrlJob.perform_later(doi)
    end

    "Queued storing missing URL in database for DOIs updated since #{from_date.strftime("%F")}."
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
#        doi.update_columns("last_landing_page_status_result": result)

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
