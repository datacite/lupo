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

  aasm :whiny_transitions => false do
    # initial is default state for new DOIs. This is needed to handle DOIs created
    # outside of this application (i.e. the MDS API)
    state :undetermined, :initial => true
    state :draft, :tombstoned, :registered, :findable, :flagged, :broken

    event :start do
      transitions :from => :undetermined, :to => :draft, :after => Proc.new { set_to_inactive }
    end

    event :register do
      # can't register test prefix
      transitions :from => [:undetermined, :draft], :to => :registered, :unless => :is_test_prefix?, :after => Proc.new { update_url }
      transitions :from => :undetermined, :to => :draft, :after => Proc.new { set_to_inactive }
    end

    event :publish do
      # can't index test prefix
      transitions :from => [:undetermined, :draft], :to => :findable, :unless => :is_test_prefix?, :after => Proc.new { update_url }
      transitions :from => :registered, :to => :findable, :after => Proc.new { set_to_active }
      transitions :from => :undetermined, :to => :draft, :after => Proc.new { set_to_inactive }
    end

    event :hide do
      transitions :from => [:findable], :to => :registered, :after => Proc.new { set_to_inactive }
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
  alias_attribute :uid, :doi
  alias_attribute :resource_type_id, :resource_type_general
  alias_attribute :resource_type_subtype, :additional_type
  alias_attribute :published, :date_published

  belongs_to :client, foreign_key: :datacentre
  has_many :media, -> { order "created DESC" }, foreign_key: :dataset, dependent: :destroy
  has_many :metadata, -> { order "created DESC" }, foreign_key: :dataset, dependent: :destroy

  delegate :provider, to: :client

  validates_presence_of :doi

  # from https://www.crossref.org/blog/dois-and-matching-regular-expressions/ but using uppercase
  validates_format_of :doi, :with => /\A10\.\d{4,5}\/[-\._;()\/:a-zA-Z0-9]+\z/
  validates_format_of :url, :with => /\Ahttps?:\/\/[\S]+/ , if: :url?, message: "URL is not valid"
  validates_uniqueness_of :doi, message: "This DOI has already been taken"
  validates :last_landing_page_status, numericality: { only_integer: true }, if: :last_landing_page_status?

  # update cached doi count for client
  before_destroy :update_doi_count
  after_create :update_doi_count
  after_update :update_doi_count, if: :saved_change_to_datacentre?

  before_save :set_defaults, :update_metadata
  before_create { self.created = Time.zone.now.utc.iso8601 }

  scope :query, ->(query) { where("dataset.doi = ?", query) }

  def doi=(value)
    write_attribute(:doi, value.upcase) if value.present?
  end

  def identifier
    normalize_doi(doi, sandbox: !Rails.env.production?)
  end

  def client_id
    client.symbol.downcase
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
    doi.split('/', 2).first
  end

  def is_test_prefix?
    prefix == "10.5072"
  end

  def is_registered_or_findable?
    %w(registered findable).include?(aasm_state)
  end

  def url=(value)
    # update url in handle system if url is present and has changed
    if value.present? && value != url && password.present? && is_registered_or_findable? && !%w(europ ethz).include?(provider_id)

      register_url(url: value, username: username, password: password)
      
      # HandleJob.perform_later(self, url: value,
      #                               username: username,
      #                               password: password)
    end

    super(value)
  end

  # update URL in handle system for registered and findable state
  # providers europ and ethz do their own handle registration
  def update_url
    set_to_active if is_active == "\x00"

    return nil if url.blank? || password.blank? || %w(europ ethz).include?(provider_id)

    register_url(url: url, username: username, password: password)

    # HandleJob.perform_later(self, url: url,
    #                         username: username,
    #                         password: password)
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
      "xml" => xml,
      "client-id" => client_id,
      "provider-id" => provider_id,
      "resource-type-id" => resource_type_general,
      "state" => aasm_state,
      "is-active" => is_active == "\x01",
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

  def resource_type
    cached_resource_type_response(resource_type_general.underscore.dasherize.downcase) if resource_type_general.present?
  end

  def date_registered
    minted
  end

  def date_updated
    updated
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
    collection = Doi.where("updated >= ?", from_date).where("updated < ?", Time.zone.now - 15.minutes)

    collection.where(is_active: "\x00").where(minted: nil).update_all(aasm_state: "draft")
    collection.where(is_active: "\x00").where.not(minted: nil).update_all(aasm_state: "registered")
    collection.where(is_active: "\x01").where.not(minted: nil).update_all(aasm_state: "findable")
    collection.where("doi LIKE ?", "10.5072%").where.not(aasm_state: "draft").update_all(aasm_state: "draft")
  rescue ActiveRecord::LockWaitTimeout => exception
    Bugsnag.notify(exception)
  end

  # delete all DOIs with test prefix 10.5072 older than from_date
  # we need to use destroy_all to also delete has_many associations for metadata and media
  def self.delete_test_dois(from_date: nil)
    from_date ||= Time.zone.now - 1.month
    collection = Doi.where("updated >= ?", from_date).where("updated < ?", Time.zone.now - 15.minutes)
    collection.where("doi LIKE ?", "10.5072%").find_each { |d| d.destroy }
  end

  # set minted date for DOIs that have been registered in an handle system (providers ETHZ and EUROP)
  def self.set_minted(from_date: nil)
    from_date ||= Time.zone.now - 1.day
    ids = ENV['HANDLES_MINTED'].to_s.split(",")
    return nil unless ids.present?

    collection = Doi.where("datacentre in (SELECT id from datacentre where allocator IN (:ids))", ids: ids).where("updated >= ?", from_date).where("updated < ?", Time.zone.now - 15.minutes)
    collection.where(is_active: "\x01").where(minted: nil).update_all(("minted = updated"))
  end

  # update metadata when any virtual attribute has changed
  def update_metadata
    changed_virtual_attributes = changed & %w(author title publisher date_published additional_type resource_type_general description)

    if changed_virtual_attributes.present?
      @xml = datacite_xml
      @schema_version = Maremma.from_xml(xml).dig("resource", "xmlns")
      attribute_will_change!(:xml)
    end
    
    metadata.build(doi: self, xml: xml, namespace: schema_version) if (changed & %w(xml)).present?
  end

  def set_defaults
    self.is_active = is_active ? "\x01" : "\x00"
    self.version = version.present? ? version + 1 : 0
    self.updated = Time.zone.now.utc.iso8601
  end

  def set_to_active
    self.is_active = "\x01"
  end

  def set_to_inactive
    self.is_active = "\x00"
  end

  private

  def update_doi_count
    Rails.cache.delete("cached_doi_count/#{datacentre}")
  end

  def set_url
    response = Maremma.head(identifier, limit: 0)
    if response.headers.present?
      update_column(:url, response.headers["location"])
      Rails.logger.debug "Set URL #{response.headers["location"]} for DOI #{doi}"
    end
  end
end
