class Prefix < ApplicationRecord
  self.table_name = "prefix"
  has_and_belongs_to_many :datacentres
  has_and_belongs_to_many :allocators
end
