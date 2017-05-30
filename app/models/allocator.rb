class Allocator < ApplicationRecord
  self.table_name = "allocator"
  has_many :datacentres
  has_and_belongs_to_many :prefixes, class_name: 'Prefix', foreign_key: :prefix
end
