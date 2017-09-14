class ProviderPrefix < ApplicationRecord
  self.table_name = "allocator_prefixes"

  belongs_to :provider, foreign_key: :allocator
  belongs_to :prefix, foreign_key: :prefixes

  alias_attribute :created_at, :created
  alias_attribute :updated_at, :updated

  before_create { self.created = Time.zone.now.utc.iso8601 }
  before_save { self.updated = Time.zone.now.utc.iso8601 }
end
