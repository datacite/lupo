class AddUuidToEnrichments < ActiveRecord::Migration[7.2]
  def change
    add_column :enrichments, :uuid, :text

    migration_enrichment = Class.new(ActiveRecord::Base) do
      self.table_name = "enrichments"
    end

    migration_enrichment.reset_column_information

    migration_enrichment.where(uuid: nil).in_batches(of: 1000) do |relation|
      relation.each { |row| row.update_columns(uuid: SecureRandom.uuid) }
    end

    change_column_null :enrichments, :uuid, false

    add_index :enrichments, :uuid, unique: true, length: 36
  end

  def down
    remove_index :enrichments, :uuid
    remove_column :enrichments, :uuid
  end
end
