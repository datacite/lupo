class RenameDatasetTable < ActiveRecord::Migration[5.2]
  def up
    # removing foreign keys using the datacentre table
    remove_foreign_key "media", name: "FK62F6FE44D3D6B1B"
    remove_foreign_key "metadata", name: "FKE52D7B2F4D3D6B1B"
    
    Lhm.change_table :dataset do |m|
      m.remove_column :is_ref_quality
      m.remove_column :version
      m.rename_column :datacentre, :repository_id
      m.rename_column :created, :created_at
      m.rename_column :updated, :updated_at
      m.change_column :is_active, "BOOLEAN DEFAULT TRUE" 
    end

    Lhm.change_table :dataset do |m|
      m.rename_column :version_info, :version
    end

    safety_assured { rename_table :dataset, :dois }
  end

  def down
    rename_table :dois, :dataset 
    
    Lhm.change_table :dataset do |m|
      m.change_column :is_active, "BIT DEFAULT 1 NOT NULL"
      m.add_column :is_ref_quality, "BIT DEFAULT 1"
      m.rename_column :version, :version_info 
      m.add_column :version, "INT(11)"
      m.rename_column :repository_id, :datacentre 
      m.rename_column :created_at, :created
      m.rename_column :updated_at, :updated
    end

    add_foreign_key "media", "dataset", column: "dataset", name: "FK62F6FE44D3D6B1B", on_delete: :cascade
    add_foreign_key "metadata", "dataset", column: "dataset", name: "FKE52D7B2F4D3D6B1B", on_delete: :cascade
  end
end
