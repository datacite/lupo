class SchemaVersionIndex < ActiveRecord::Migration[5.2]
  def change
    add_index :dataset, [:schema_version]
  end
end
