require 'maremma'

class Doi < ActiveRecord::Base
  include Metadatable
  include Cacheable
  include Licensable

  # include helper module for generating random DOI suffixes
  include Helpable

  # include helper module for converting and exposing metadata
  include Crosscitable

  # include helper module for link checking
  include Checkable

  # include state machine
  include AASM

  # include helper module for Elasticsearch
  include Indexable

  # include helper module for sending emails
  include Mailable

  include Elasticsearch::Model

  aasm :whiny_transitions => false do
    # initial is default state for new DOIs. This is needed to handle DOIs created
    # outside of this application (i.e. the MDS API)
    state :undetermined, :initial => true
    state :draft, :tombstoned, :registered, :findable, :flagged, :broken

    event :start do
      transitions :from => :undetermined, :to => :draft
    end

    event :register do
      # can't register test prefix
      transitions :from => [:undetermined, :draft], :to => :registered, :unless => :is_test_prefix?
      transitions :from => :undetermined, :to => :draft
    end

    event :publish do
      # can't index test prefix
      transitions :from => [:undetermined, :draft], :to => :findable, :unless => :is_test_prefix?
      transitions :from => :registered, :to => :findable
      transitions :from => :undetermined, :to => :draft
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
  alias_attribute :resource_type_subtype, :additional_type
  alias_attribute :published, :date_published
  alias_attribute :registered, :minted

  attr_accessor :current_user
  attr_accessor :validate

  belongs_to :client, foreign_key: :datacentre
  has_many :media, -> { order "created DESC" }, foreign_key: :dataset, dependent: :destroy
  has_many :metadata, -> { order "created DESC" }, foreign_key: :dataset, dependent: :destroy

  delegate :provider, to: :client

  validates_presence_of :doi
  # validates_presence_of :url, if: :is_registered_or_findable?

  # from https://www.crossref.org/blog/dois-and-matching-regular-expressions/ but using uppercase
  validates_format_of :doi, :with => /\A10\.\d{4,5}\/[-\._;()\/:a-zA-Z0-9]+\z/
  validates_format_of :url, :with => /\A(ftp|http|https):\/\/[\S]+/ , if: :url?, message: "URL is not valid"
  validates_uniqueness_of :doi, message: "This DOI has already been taken"
  validates :last_landing_page_status, numericality: { only_integer: true }, if: :last_landing_page_status?

  # validate :validation_errors

  # update cached doi count for client
  before_destroy :update_doi_count
  after_create :update_doi_count
  after_update :update_doi_count, if: :saved_change_to_datacentre?
  after_commit :update_url, on: [:create, :update]
  after_commit :update_media, on: [:create, :update]

  before_save :set_defaults, :update_metadata
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
    indexes :author_normalized,              type: :object, properties: {
      type: { type: :keyword },
      id: { type: :keyword },
      name: { type: :text },
      "given-name" => { type: :text },
      "family-name" => { type: :text }
    }
    indexes :author_names,                   type: :text
    indexes :title_normalized,               type: :text
    indexes :description_normalized,         type: :text
    indexes :publisher,                      type: :text, fields: { keyword: { type: "keyword" }}
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
      created: { type: :date },
      updated: { type: :date }
    }
    indexes :alternate_identifier,           type: :object, properties: {
      type: { type: :keyword },
      name: { type: :keyword }
    }
    indexes :resource_type_subtype,          type: :keyword
    indexes :version,                        type: :integer
    indexes :is_active,                      type: :keyword
    indexes :aasm_state,                     type: :keyword
    indexes :schema_version,                 type: :keyword
    indexes :metadata_version,               type: :keyword
    indexes :source,                         type: :keyword
    indexes :prefix,                         type: :keyword
    indexes :suffix,                         type: :keyword
    indexes :reason,                         type: :text
    indexes :xml,                            type: :text, index: "no"
    indexes :last_landing_page_status,       type: :integer
    indexes :last_landing_page_status_check, type: :date
    indexes :last_landing_page_content_type, type: :keyword
    indexes :cache_key,                      type: :keyword
    indexes :published,                      type: :date, format: "yyyy-MM-dd||yyyy-MM||yyyy", ignore_malformed: true
    indexes :registered,                     type: :date
    indexes :created,                        type: :date
    indexes :updated,                        type: :date

    # include parent objects
    indexes :client,        type: :object
    indexes :resource_type, type: :object
  end

  def as_indexed_json(options={})
    {
      "id" => uid,
      "uid" => uid,
      "doi" => doi,
      "identifier" => identifier,
      "url" => url,
      "author_normalized" => author_normalized,
      "author_names" => author_names,
      "title_normalized" => title_normalized,
      "description_normalized" => description_normalized,
      "publisher" => publisher,
      "client_id" => client_id,
      "provider_id" => provider_id,
      "media_ids" => media_ids,
      "prefix" => prefix,
      "suffix" => suffix,
      "resource_type_id" => resource_type_id,
      "resource_type_subtype" => resource_type_subtype,
      "alternate_identifier" => alternate_identifier,
      "b_version" => b_version,
      "is_active" => is_active,
      "last_landing_page_status" => last_landing_page_status,
      "last_landing_page_status_check" => last_landing_page_status_check,
      "last_landing_page_content_type" => last_landing_page_content_type,
      "aasm_state" => aasm_state,
      "schema_version" => schema_version,
      "metadata_version" => metadata_version,
      "reason" => reason,
      "xml_encoded" => xml_encoded,
      "source" => source,
      "cache_key" => cache_key,
      "published" => published,
      "registered" => registered,
      "created" => created,
      "updated" => updated,
      "client" => client.as_indexed_json,
      "resource_type" => resource_type.try(:as_indexed_json),
      "media" => media.map { |m| m.try(:as_indexed_json) }
    }
  end

  def self.query_aggregations
    {
      resource_types: { terms: { field: 'resource_type_general', size: 15, min_doc_count: 1 } },
      states: { terms: { field: 'aasm_state', size: 10, min_doc_count: 1 } },
      years: { date_histogram: { field: 'published', interval: 'year', min_doc_count: 1 } },
      created: { date_histogram: { field: 'created', interval: 'year', min_doc_count: 1 } },
      providers: { terms: { field: 'provider_id', size: 10, min_doc_count: 1 } },
      clients: { terms: { field: 'client_id', size: 10, min_doc_count: 1 } },
      prefixes: { terms: { field: 'prefix', size: 10, min_doc_count: 1 } },
      schema_versions: { terms: { field: 'schema_version', size: 10, min_doc_count: 1 } },
      sources: { terms: { field: 'source', size: 10, min_doc_count: 1 } }
    }
  end

  def self.query_fields
    ['doi^10', 'title_normalized^10', 'author_names^10', 'author_normalized.name^10', 'author_normalized.id^10', 'publisher^10', 'description_normalized^10', 'resource_type_id^10', 'resource_type_subtype^10', 'alternate_identifier.name^10', '_all']
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

  def self.index(options={})
    from_date = (options[:from_date].present? ? Date.parse(options[:from_date]) : Date.current).beginning_of_month
    until_date = (options[:until_date].present? ? Date.parse(options[:until_date]) : Date.current).end_of_month

    # get first day of every month between from_date and until_date
    (from_date..until_date).each do |d|
      DoiIndexByDayJob.perform_later(from_date: d.strftime("%F"))
    end

    "Queued indexing for DOIs updated from #{from_date.strftime("%F")} until #{until_date.strftime("%F")}."
  end

  def self.index_by_day(options={})
    from_date = options[:from_date].present? ? Date.parse(options[:from_date]) : Date.current
    until_date = from_date + 1.day
    errors = 0
    count = 0

    logger = Logger.new(STDOUT)

    Doi.where("updated >= ?", from_date.strftime("%F") + " 00:00:00").where("updated <= ?", until_date.strftime("%F") + " 00:00:00").find_in_batches(batch_size: 100) do |dois|
      response = Doi.__elasticsearch__.client.bulk \
        index:   Doi.index_name,
        type:    Doi.document_type,
        body:    dois.map { |doi| { index: { _id: doi.id, data: doi.as_indexed_json } } }

      errors += response['items'].map { |k, v| k.values.first['error'] }.compact.length
      count += dois.length
    end

    logger.info "[Elasticsearch] #{errors} errors indexing #{count} DOIs updated on #{from_date.strftime("%F")}."
  end

  def uid
    doi.downcase
  end

  def resource_type_id
    resource_type_general.downcase if resource_type_general.present?
  end

  def media_ids
    media.pluck(:id).map { |m| Base32::URL.encode(m, split: 4, length: 16) }
  end

  def xml_encoded
    Base64.strict_encode64(xml) if xml.present?
  rescue ArgumentError => exception    
    nil
  end
  
  def title_normalized
    parse_attributes(title, content: "text", first: true)
  end

  def description_normalized
    parse_attributes(description, content: "text", first: true)
  end

  def author_normalized
    Array.wrap(author)
  end
 
  # author name in natural order: "John Smith" instead of "Smith, John"
  def author_names
    Array.wrap(author).map do |a| 
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
    r = cached_client_response(value)
    return @client_id unless r.present?

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

  def is_registered_or_findable?
    %w(registered findable).include?(aasm_state)
  end

  # update URL in handle system for registered and findable state
  # providers europ and ethz do their own handle registration
  def update_url
    return nil if current_user.nil? || !is_registered_or_findable? || %w(europ ethz).include?(provider_id)

    HandleJob.set(wait: 1.minute).perform_later(doi)
  end

  def update_media
    return nil unless content_url.present?

    media.delete_all

    Array.wrap(content_url).each do |c|
      media << Media.create(url: c, media_type: content_format)
    end
  end

  # attributes to be sent to elasticsearch index
  def to_jsonapi
    attributes = {
      "doi" => doi,
      "identifier" => identifier,
      "url" => url,
      "creator" => author,
      "title" => title,
      "publisher" => publisher,
      "resource-type-subtype" => additional_type,
      "version" => version,
      "schema-version" => schema_version,
      "metadata-version" => metadata_version,
      "client-id" => client_id,
      "provider-id" => provider_id,
      "resource-type-id" => resource_type_general,
      "prefix" => prefix,
      "state" => aasm_state,
      "source" => source,
      "is-active" => is_active == "\x01",
      "created" => created,
      "published" => date_published,
      "registered" => date_registered,
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
    cached_resource_type_response(resource_type_general.underscore.dasherize.downcase) if resource_type_general.present?
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
    self.send(value) if %w(start register publish hide).include?(value)
  end

  def timestamp
    updated.utc.iso8601 if updated.present?
  end

  # update state for all DOIs starting from from_date
  def self.set_state(from_date: nil)
    from_date ||= Time.zone.now - 1.day
    collection = Doi.where("updated >= ?", from_date).where("updated < ?", Time.zone.now - 15.minutes).where(aasm_state: '')

    collection.where(is_active: "\x00").where(minted: nil).update_all(aasm_state: "draft")
    collection.where(is_active: "\x00").where.not(minted: nil).update_all(aasm_state: "registered")
    collection.where(is_active: "\x01").where.not(minted: nil).update_all(aasm_state: "findable")
    collection.where("doi LIKE ?", "10.5072%").where.not(aasm_state: "draft").update_all(aasm_state: "draft")
  rescue ActiveRecord::LockWaitTimeout => exception
    Bugsnag.notify(exception)
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

  # update metadata when any virtual attribute has changed
  def update_metadata
    changed_virtual_attributes = changed & %w(author title publisher date_published additional_type resource_type_general description content_size content_format)

    if changed_virtual_attributes.present?
      @xml = datacite_xml
      doc = Nokogiri::XML(xml, nil, 'UTF-8', &:noblanks)
      ns = doc.collect_namespaces.find { |k, v| v.start_with?("http://datacite.org/schema/kernel") }
      @schema_version = Array.wrap(ns).last || "http://datacite.org/schema/kernel-4"
      attribute_will_change!(:xml)
    end
    
    metadata.build(doi: self, xml: xml, namespace: schema_version) if (changed & %w(xml)).present?
  end

  def set_defaults
    self.start if aasm_state == "undetermined"
    self.is_active = (aasm_state == "findable") ? "\x01" : "\x00"
    self.version = version.present? ? version + 1 : 0
    self.updated = Time.zone.now.utc.iso8601
  end

  private

  def update_doi_count
    Rails.cache.delete("cached_doi_count/#{datacentre}")
  end

  def set_url
    response = Maremma.head(identifier, limit: 0)
    if response.headers.present?
      update_column(:url, response.headers["location"])
      logger = Logger.new(STDOUT)
      logger.debug "Set URL #{response.headers["location"]} for DOI #{doi}"
    end
  end
end
