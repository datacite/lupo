class Dataset < ApplicationRecord
  self.table_name = "dataset"
  alias_attribute :datacentre_id, :datacentre
  belongs_to :datacentre, class_name: 'Datacentre', foreign_key: :datacentre
end
