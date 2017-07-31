class Member < ApplicationRecord
  self.table_name = "allocator"
  alias_attribute :created_at, :created
  alias_attribute :updated_at, :updated
  alias_attribute :member_id, :id
  has_many :datacentres
  has_and_belongs_to_many :prefixes, class_name: 'Prefix', join_table: "allocator_prefixes", foreign_key: :prefixes, association_foreign_key: :allocator


  def member_type
    return "allocating"  if doi_quota_allowed >= 0
    "non_allocating"
  end
end
