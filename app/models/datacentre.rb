class Datacentre < ApplicationRecord
  self.table_name = "datacentre"
  alias_attribute :allocator_id, :allocator
  validates_presence_of :name
  has_and_belongs_to_many :prefixes, class_name: 'Prefix', foreign_key: :prefix
  belongs_to :allocator, class_name: 'Allocator', foreign_key: :allocator
  has_many :datasets
end
