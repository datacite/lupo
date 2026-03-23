class AddSourceIdToEnrichments < ActiveRecord::Migration[7.2]
  disable_departure!

  def change
    add_column :enrichments, :source_id, :string, limit: 255, null: false
  end
end
