class Metadata < ActiveRecord::Base
  # define table and attribute names
  # uid is used as unique identifier, mapped to id in serializer
  attribute :dataset_id
  alias_attribute :uid, :id
  alias_attribute :created_at, :created
  alias_attribute :updated_at, :updated
  validates_presence_of :dataset, :xml, :metadata_version, :url
  validates_uniqueness_of :uid, message: "This name has already been taken"
  validates_numericality_of :version, if: :version?
  validates_format_of :url, :with => /https?:\/\/[\S]+/ , if: :url?, message: "Website should be an url"
  # validates_inclusion_of :metadata_version, :in => %w( 1 2 3 4 ), :message => "Metadata version is not included in the list", if: :metadata_version?

  belongs_to :dataset, class_name: 'Dataset', foreign_key: :dataset
  before_validation :set_dataset

  before_create { self.created = Time.zone.now.utc.iso8601 }


  scope :query, ->(query) { where("symbol like ? OR name like ?", "%#{query}%", "%#{query}%") }

  private

  def set_dataset
    r = Dataset.where(doi: dataset_id).first
    fail("dataset_id Not found") unless r.present?
    write_attribute(:dataset, r.id)
  end
end
