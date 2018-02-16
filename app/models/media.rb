class Media < ActiveRecord::Base
  include Bolognese::Utils
  include Bolognese::DoiUtils

  include Cacheable

  alias_attribute :created_at, :created
  alias_attribute :updated_at, :updated
  validates_presence_of  :url, :media_type
  validates_format_of :url, :with => /https?:\/\/[\S]+/, if: :url?
  validates_format_of :media_type, :with => /[\S]+\/[\S]+/, if: :media_type?
  validates_associated :doi

  belongs_to :doi, foreign_key: :dataset

  before_validation :set_media_version
  before_create { self.created = Time.zone.now.utc.iso8601 }
  before_save { self.updated = Time.zone.now.utc.iso8601 }

  def uid
    Base32::URL.encode(id, split: 4, length: 16)
  end

  def doi_id
    doi.doi
  end

  def doi_id=(value)
    r = Doi.where(doi: value).first
    fail ActiveRecord::RecordNotFound unless r.present?

    write_attribute(:dataset, r.id)
  end

  def set_media_version
    current_media = Media.where(dataset: dataset).order('media.created DESC').first
    self.version = current_media.present? ? current_media.version + 1 : 0
  end
end
