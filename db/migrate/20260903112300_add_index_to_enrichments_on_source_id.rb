class AddIndexToEnrichmentsOnSourceId < ActiveRecord::Migration[7.2]
  disable_departure!

  def change
    add_index :enrichments, :source_id, name: "index_enrichments_on_source_id"
  end
end
