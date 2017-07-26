class Dataset < ApplicationRecord
  alias_attribute :datacentre_id, :datacentre
  alias_attribute :created_at, :created
  alias_attribute :updated_at, :updated
  belongs_to :datacentre, class_name: 'Datacentre', foreign_key: :datacentre
  self.table_name = "dataset"
end
