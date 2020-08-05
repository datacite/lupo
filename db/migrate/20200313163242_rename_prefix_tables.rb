class RenamePrefixTables < ActiveRecord::Migration[5.2]
  def change
    rename_column :prefix, :created, :created_at
    rename_column :prefix, :prefix, :uid
    remove_column :prefix, :version, :integer
    remove_column :prefix, :updated, :datetime
    rename_table :prefix, :prefixes

    rename_column :allocator_prefixes, :allocator, :provider_id
    rename_column :allocator_prefixes, :prefixes, :prefix_id
    add_column :allocator_prefixes, :uid, :string, null: false
    rename_table :allocator_prefixes, :provider_prefixes
    add_index :provider_prefixes, [:uid], length: 128

    rename_column :datacentre_prefixes, :datacentre, :client_id
    rename_column :datacentre_prefixes, :prefixes, :prefix_id
    rename_column :datacentre_prefixes, :allocator_prefixes, :provider_prefix_id
    add_column :datacentre_prefixes, :uid, :string, null: false
    rename_table :datacentre_prefixes, :client_prefixes
    add_index :client_prefixes, [:uid], length: 128
  end
end
