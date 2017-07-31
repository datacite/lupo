class Prefix < ApplicationRecord
  self.table_name = "prefix"
  alias_attribute :created_at, :created
  has_and_belongs_to_many :datacentres, join_table: "datacentre_prefixes", foreign_key: :prefixes, association_foreign_key: :datacentre
  has_and_belongs_to_many :allocators, join_table: "allocator_prefixes", foreign_key: :prefixes, association_foreign_key: :allocator

  def set_updated_at
    "NA"
  end
end
