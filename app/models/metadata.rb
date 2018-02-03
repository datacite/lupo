class Metadata < ActiveRecord::Base
  include Bolognese::Utils
  include Bolognese::DoiUtils

  include Cacheable

  alias_attribute :created_at, :created
  validates_presence_of :xml, :namespace, :metadata_version
  validates_numericality_of :version, if: :version?
  validates_numericality_of :metadata_version, if: :metadata_version?

  belongs_to :doi, foreign_key: :dataset

  before_validation :set_metadata_version
  before_create { self.created = Time.zone.now.utc.iso8601 }

  def uid
    Base32::URL.encode(id, split: 4, length: 16)
  end

  def xml=(value)
    write_attribute(:xml, Base64.decode64(value))
  end

  def doi_id
    doi.doi
  end

  def doi_id=(value)
    r = Doi.where(doi: value).first
    fail ActiveRecord::RecordNotFound unless r.present?

    write_attribute(:dataset, r.id)
  end

  def set_metadata_version
    current_metadata = Metadata.where(dataset: dataset).order('metadata.created DESC').first
    self.metadata_version = current_metadata.present? ? current_metadata.metadata_version + 1 : 0
  end
end
