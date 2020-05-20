class RenameAllocatorTable < ActiveRecord::Migration[5.2]
  def up
    # removing foreign keys using the datacentre table
    remove_foreign_key "provider_prefixes", name: "FKE7FBD67446EBD781"
    
    Lhm.change_table :allocator do |m|
      m.remove_column :comments
      m.remove_column :doi_quota_allowed
      m.remove_column :doi_quota_used
      m.remove_column :experiments
      m.remove_column :version
      m.add_column :uid, "VARCHAR(32)"
      m.add_index ["uid(32)"], :index_uid
      m.rename_column :created, :created_at
      m.rename_column :updated, :updated_at
      m.change_column :is_active, "BOOLEAN DEFAULT TRUE" 
    end

    safety_assured { rename_table :allocator, :members }
  end

  def down
    rename_table :members, :allocator 
    
    Lhm.change_table :allocator do |m|
      m.change_column :is_active, "BIT DEFAULT 1"
      m.add_column :comments, "LONGTEXT"
      m.add_column :doi_quota_allowed, "INT(11) NOT NULL"
      m.add_column :doi_quota_used, "INT(11) NOT NULL"
      m.add_column :experiments, "VARCHAR(255)"
      m.add_column :version, "INT(11)"
      m.remove_column :uid
      m.rename_column :created_at, :created
      m.rename_column :updated_at, :updated
    end

    add_foreign_key "provider_prefixes", "allocator", column: "provider_id", name: "FKE7FBD67446EBD781", on_delete: :cascade
  end
end
