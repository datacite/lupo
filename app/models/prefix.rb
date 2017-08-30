class Prefix < ActiveRecord::Base
  self.table_name = "prefix"
  alias_attribute :created_at, :created
  alias_attribute :updated_at, :updated
  alias_attribute :uid, :prefix

  validates_presence_of :prefix
  validates_uniqueness_of :prefix

  # validates_format_of :prefix, :with => /(10\.\d{4,5})\/.+\z/, :multiline => true
  validates_numericality_of :version, if: :version?

  has_and_belongs_to_many :datacenters, join_table: "datacentre_prefixes", foreign_key: :prefixes, association_foreign_key: :datacentre, autosave: true
  alias_attribute :data_centers, :datacenters
  has_and_belongs_to_many :members, join_table: "allocator_prefixes", foreign_key: :prefixes, association_foreign_key: :allocator, autosave: true  

  before_create { self.created = Time.zone.now.utc.iso8601 }
  before_save { self.updated = Time.zone.now.utc.iso8601 }

  scope :query, ->(query) { where("prefix like ?", "%#{query}%") }

  def registration_agency
    "DataCite"
  end
end
