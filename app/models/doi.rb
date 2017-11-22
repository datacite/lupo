require 'maremma'

class Doi < ActiveRecord::Base
  include Identifiable
  include Metadatable
  include Cacheable
  include Licensable

  # include state machine
  include AASM

  aasm :column => 'state', :whiny_transitions => false do
    # new is default state for new DOIs. This is needed to handle DOIs created
    # outside of this application (i.e. the MDS API)
    state :new, :initial => true
    state :draft, :tombstoned, :registered, :findable, :flagged, :broken, :deleted

    event :draft do
      transitions :from => :new, :to => :draft
    end

    event :register do
      # can't register test prefix
      transitions :from => [:new, :draft], :to => :registered, :unless => :is_test_prefix?
    end

    event :publish do
      transitions :from => [:new, :draft, :tombstoned, :registered], :to => :findable, :unless => :is_test_prefix?
    end

    event :flag do
      transitions :from => [:registered, :findable], :to => :flagged
    end

    event :link_check do
      transitions :from => [:tombstoned, :registered, :findable, :flagged], :to => :broken
    end

    # can only delete if state is :draft
    event :remove do
      after do
        destroy
      end

      transitions :from => [:draft], :to => :deleted
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
  validates_format_of :url, :with => /https?:\/\/[\S]+/ , if: :url?, message: "Website should be an url"
  validates_uniqueness_of :doi, message: "This DOI has already been taken"
  validates_numericality_of :version, if: :version?

  # update cached doi count for client
  before_destroy :update_doi_count
  after_create :update_doi_count
  after_update :update_doi_count, if: :datacentre_changed?

  before_save :set_defaults
  before_create { self.created = Time.zone.now.utc.iso8601 }
  before_save { self.updated = Time.zone.now.utc.iso8601 }
  after_save { UrlJob.perform_later(self) }

  scope :query, ->(query) { where("dataset.doi = ?", query) }

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

  # def provider
  #   r = cached_client_response(client_id)
  #   fail ActiveRecord::RecordNotFound unless r.present?
  #
  #   r.allocator
  # end

  def prefix
    doi.split('/', 2).first
  end

  def is_test_prefix?
    prefix == "10.5072"
  end

  def identifier
    doi_as_url(doi)
  end

  def resource_type
    return nil unless resource_type_general.present?
    r = ResourceType.where(id: resource_type_general.downcase.underscore.dasherize)
    r[:data] if r.present?
  end

  # parse metadata using bolognese library
  def doi_metadata
    current_metadata = metadata.order('metadata.created DESC').first

    # return OpenStruct if no metadata record is found to handle delegate
    return OpenStruct.new unless current_metadata

    DoiSearch.new(input: current_metadata.xml,
                  from: "datacite",
                  doi: doi,
                  sandbox: !Rails.env.production?)
  end

  delegate :author, :title, :container_title, :description, :resource_type_general,
    :additional_type, :license, :related_identifier, :schema_version,
    :date_published, :date_accepted, :date_available, :publisher, :xml, to: :doi_metadata

  def date_registered
    minted
  end

  def date_updated
    updated
  end

  def state
    if Rails.env.production?
      is_active == "\x01" ? "findable" : "registered"
    else
      @state
    end
  end

  # update state for all DOIs starting from from_date
  def self.set_state(from_date)
    from_date ||= Time.zone.now - 1.day
    Doi.where("updated >= ?", from_date).where(minted: nil).update_all(state: "draft")
    Doi.where(state: "new").where("updated >= ?", from_date).where(is_active: "\x00").where.not(minted: nil).update_all(state: "registered")
    Doi.where(state: "new").where("updated >= ?", from_date).where(is_active: "\x01").where.not(minted: nil).update_all(state: "findable")
    Doi.where("updated >= ?", from_date).where("doi LIKE ?", "10.5072%").update_all(state: "draft")
  end

  # delete all DOIs with test prefix 10.5072 older than from_date
  # we need to use destroy_all to also delete has_many associations for metadata and media
  def self.delete_test_dois(from_date)
    from_date ||= Time.zone.now - 1.month
    Doi.where("updated <= ?", from_date).where("doi LIKE ?", "10.5072%").find_each { |d| d.destroy }
  end

  private

  def set_defaults
    self.doi = doi.upcase
    self.is_active = is_active? ? "\x01" : "\x00"
  end

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
