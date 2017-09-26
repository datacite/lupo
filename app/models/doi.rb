require 'maremma'

class Doi < ActiveRecord::Base
  include Identifiable
  include Metadatable
  include Cacheable
  include Licensable

  self.table_name = "dataset"
  alias_attribute :created_at, :created
  alias_attribute :updated_at, :updated
  alias_attribute :uid, :doi

  belongs_to :client, foreign_key: :datacentre
  has_many :media, foreign_key: :dataset
  has_many :metadata, foreign_key: :dataset

  delegate :provider, to: :client

  validates_presence_of :uid, :doi
  validates_format_of :doi, :with => /(10\.\d{4,5})\/.+\z/
  validates_format_of :url, :with => /https?:\/\/[\S]+/ , if: :url?, message: "Website should be an url"
  validates_uniqueness_of :doi, message: "This DOI has already been taken"
  validates_numericality_of :version, if: :version?

  before_validation :set_defaults
  before_create { self.created = Time.zone.now.utc.iso8601 }
  before_save { self.updated = Time.zone.now.utc.iso8601 }
  after_save { UrlJob.perform_later(self) }

  def client_id=(value)
    r = cached_client_response(value)
    fail ActiveRecord::RecordNotFound unless r.present?

    write_attribute(:datacentre, r.id)
  end

  # def client_id
  #
  # end
  #
  # def provider_id
  #
  # end

  # def provider
  #   r = cached_client_response(client_id)
  #   fail ActiveRecord::RecordNotFound unless r.present?
  #
  #   r.allocator
  # end

  def identifier
    doi_as_url(doi)
  end

  # parse metadata using bolognese library
  def doi_metadata
    current_metadata = metadata.order('metadata.created DESC').first
    return nil unless current_metadata

    DoiSearch.new(input: current_metadata.xml,
                  from: "datacite",
                  sandbox: !Rails.env.production?)
  end

  delegate :author, :title, :container_title, :description, :resource_type_general,
    :additional_type, :license, :version, :related_identifier, :schema_version,
    :date_published, :publisher, :xml, to: :doi_metadata

  def date_registered
    minted
  end

  def date_updated
    updated
  end

  def state
    is_active == "\x01" ? "searchable" : "hidden"
  end

  private

  def set_url
    response = Maremma.head(identifier, limit: 0)
    if response.headers.present?
      update_column(:url, response.headers["location"])
      Rails.logger.debug "Set URL #{response.headers["location"]} for DOI #{doi}"
    end
  end

  # def set_defaults
  #  set_datacentre unless datacentre
  # end
end
