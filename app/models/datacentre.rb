class Datacentre < ApplicationRecord
  self.table_name = "datacentre"
  alias_attribute :allocator_id, :allocator
  validates_presence_of :name
  has_and_belongs_to_many :prefixes, class_name: 'Prefix', join_table: "datacentre_prefixes", foreign_key: :prefixes, association_foreign_key: :datacentre
  belongs_to :allocator, class_name: 'Allocator', foreign_key: :allocator
  has_many :datasets
end
