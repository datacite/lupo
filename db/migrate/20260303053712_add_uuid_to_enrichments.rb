class AddUuidToEnrichments < ActiveRecord::Migration[7.2]
  def change
    add_column :enrichments, :uuid, :string, limit: 36, null: false

    add_index :enrichments, :uuid, unique: true
  end
end
