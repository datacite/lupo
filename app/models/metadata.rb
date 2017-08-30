class Metadata < ActiveRecord::Base
  # define table and attribute names
  # uid is used as unique identifier, mapped to id in serializer
  # alias_attribute :dataset_id, :dataset
  alias_attribute :uid, :id
  alias_attribute :created_at, :created
  alias_attribute :updated_at, :updated
  validates_presence_of :uid, :dataset, :xml, :metadata_version
  validates_uniqueness_of :uid, message: "This name has already been taken"
  validates_format_of :url, :with => /https?:\/\/[\S]+/ , if: :website?, message: "Website should be an url"
  validates_numericality_of :version, if: :version?
  validates_inclusion_of :metadata_version, :in => %w( 1 2 3 4 ), :message => "Metadata version is not included in the list", if: :metadata_version?

  belongs_to :dataset, class_name: 'Dataset', foreign_key: :dataset

  before_create { self.created = Time.zone.now.utc.iso8601 }
  before_save { self.updated = Time.zone.now.utc.iso8601 }


  scope :query, ->(query) { where("symbol like ? OR name like ?", "%#{query}%", "%#{query}%") }

end
