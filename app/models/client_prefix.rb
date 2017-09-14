class ClientPrefix < ApplicationRecord
  self.table_name = "datacentre_prefixes"
  
  belongs_to :client, foreign_key: :datacentre
  belongs_to :prefix, foreign_key: :prefixes

  alias_attribute :created_at, :created
  alias_attribute :updated_at, :updated

  before_create { self.created = Time.zone.now.utc.iso8601 }
  before_save { self.updated = Time.zone.now.utc.iso8601 }
end
