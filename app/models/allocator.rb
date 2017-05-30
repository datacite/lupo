class Allocator < ApplicationRecord
  self.table_name = "allocator"
  has_many :datacentres
  has_and_belongs_to_many :prefixes, class_name: 'Prefix', join_table: "allocator_prefixes", foreign_key: :prefixes, association_foreign_key: :allocator
end
