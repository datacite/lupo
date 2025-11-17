# frozen_string_literal: true

class Media < ApplicationRecord
  include Bolognese::Utils
  include Bolognese::DoiUtils

  include Cacheable

  alias_attribute :created_at, :created
  alias_attribute :updated_at, :updated

  validates_presence_of :url
  validates_format_of :url,
                      with: %r{\A(ftp|http|https|gs|s3|dos)://\S+},
                      if: :url?
  validates_associated :doi

  belongs_to :doi, foreign_key: :dataset, inverse_of: :media

  before_create { self.created = Time.zone.now.utc.iso8601 }
  before_save :set_defaults

  def as_indexed_json(_options = {})
    {
      "id" => uid,
      "uid" => uid,
      "version" => version,
      "url" => url,
      "media_type" => media_type,
      "created" => created,
      "updated" => updated,
    }
  end

  def uid
    Base32::URL.encode(id, split: 4, length: 16)
  end

  def doi_id
    doi.doi
  end

  def doi_id=(value)
    r = Doi.where(doi: value).first
    fail ActiveRecord::RecordNotFound if r.blank?

    write_attribute(:dataset, r.id)
  end

  alias_method :datacite_doi_id, :doi_id

  def set_defaults
    current_media =
      Media.where(dataset: dataset).order("created DESC").first
    self.version = current_media.present? ? current_media.version + 1 : 0
    self.media_type = "text/plain" if media_type.blank?
    self.updated = Time.zone.now.utc.iso8601
  end
end
