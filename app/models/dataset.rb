class Dataset < ApplicationRecord
  alias_attribute :datacentre_id, :datacentre
  belongs_to :datacentre, class_name: 'Datacentre', foreign_key: :datacentre
  self.table_name = "dataset"
end
