class Dataset < ApplicationRecord
  attribute :datacenter_id
  alias_attribute :datacenter_id, :datacentre
  alias_attribute :created_at, :created
  alias_attribute :updated_at, :updated
  belongs_to :datacenter, class_name: 'Datacenter', foreign_key: :datacentre
  self.table_name = "dataset"

  validates_presence_of :doi, :datacentre
  validates_format_of :doi, :with => /(10\.\d{4,5})\/.+\z/
  validates_uniqueness_of :doi, message: "This DOI has already been taken"
  validates_numericality_of :version, if: :version?

end
