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
    state :inactive, :initial => true
    state :draft, :tombstoned, :registered, :findable, :flagged, :broken

    event :start do
      transitions :from => :inactive, :to => :draft, :after => Proc.new { set_to_inactive }
    end

    event :register do
      # can't register test prefix
      transitions :from => [:inactive, :draft], :to => :registered, :unless => :is_test_prefix?, :after => Proc.new { set_to_inactive }

      transitions :from => :inactive, :to => :draft, :after => Proc.new { set_to_inactive }
    end

    event :publish do
      # can't index test prefix
      transitions :from => [:inactive, :draft, :registered], :to => :findable, :unless => :is_test_prefix?, :after => Proc.new { set_to_active }

      transitions :from => :inactive, :to => :draft, :after => Proc.new { set_to_inactive }
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

  belongs_to :client, foreign_key: :datacentre
  has_many :media, foreign_key: :dataset, dependent: :destroy
  has_many :metadata, foreign_key: :dataset, dependent: :destroy

  delegate :provider, to: :client

  validates_presence_of :doi

  # from https://www.crossref.org/blog/dois-and-matching-regular-expressions/ but using uppercase
  validates_format_of :doi, :with => /\A10\.\d{4,5}\/[-\._;()\/:a-zA-Z0-9]+\z/
  validates_format_of :url, :with => /https?:\/\/[\S]+/ , if: :url?, message: "URL is not valid"
  validates_uniqueness_of :doi, message: "This DOI has already been taken"

  # update cached doi count for client
  before_destroy :update_doi_count
  after_create :update_doi_count
  after_update :update_doi_count, if: :saved_change_to_datacentre?

  # update url in handle system
  after_save :update_url, if: :saved_change_to_url?

  before_save :set_defaults
  before_create { self.created = Time.zone.now.utc.iso8601 }
  before_save { self.updated = Time.zone.now.utc.iso8601 }

  after_find :load_doi_metadata

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
    fail ActiveRecord::RecordNotFound unless r.present?

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

  # update URL in handle system, don't do that for draft state
  def update_url
    return nil if draft? || password.blank?

    HandleJob.perform_later(self, url: url,
                       username: username,
                       password: password,
                       sandbox: !Rails.env.production?)
  end

  # attributes to be sent to elasticsearch index
  def to_jsonapi
    attributes = {
      "doi" => doi,
      "identifier" => identifier,
      "url" => url,
      "author" => author,
      "title" => title,
      "publisher" => publisher,
      "publication_year" => publication_year,
      "additional-type" => additional_type,
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

  def validation_errors?
    validation_errors.present?
  end

  def current_metadata
    metadata.order('metadata.created DESC').first
  end

  def metadata_version
    current_metadata ? current_metadata.metadata_version : 0
  end

  def schema_version
    @schema_version ||= current_metadata ? current_metadata.namespace : "http://datacite.org/schema/kernel-4"
  end

  def resource_type
    cached_resource_type_response(resource_type_general.downcase.underscore.dasherize) if resource_type_general.present?
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

  # update state for all DOIs starting from from_date
  def self.set_state(from_date: nil)
    from_date ||= Time.zone.now - 1.day
    Doi.where("updated >= ?", from_date).where(minted: nil).update_all(aasm_state: "draft")
    Doi.where("updated >= ?", from_date).where(is_active: "\x00").where.not(minted: nil).update_all(aasm_state: "registered")
    Doi.where("updated >= ?", from_date).where(is_active: "\x01").where.not(minted: nil).update_all(aasm_state: "findable")
    Doi.where("updated >= ?", from_date).where("doi LIKE ?", "10.5072%").update_all(aasm_state: "draft")
  end

  # delete all DOIs with test prefix 10.5072 older than from_date
  # we need to use destroy_all to also delete has_many associations for metadata and media
  def self.delete_test_dois(from_date: nil)
    from_date ||= Time.zone.now - 1.month
    Doi.where("updated <= ?", from_date).where("doi LIKE ?", "10.5072%").find_each { |d| d.destroy }
  end

  # set minted date for DOIs have been registered in the handle system externally for ETHZ
  def self.set_minted(from_date: nil)
    from_date ||= Time.zone.now - 1.day
    p = cached_provider_response("ETHZ")
    return nil unless p.present?

    Doi.where("datacentre in (SELECT id from datacentre where allocator = ?)", p.id).where("updated >= ?", from_date).where(is_active: "\x01").where(minted: nil).update_all(("minted = updated"))
  end

  def set_defaults
    self.is_active = is_active ? "\x01" : "\x00"
    self.version = version.present? ? version + 1 : 0
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
