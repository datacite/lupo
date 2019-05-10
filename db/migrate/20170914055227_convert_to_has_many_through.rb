# frozen_string_literal: true

class ConvertToHasManyThrough < ActiveRecord::Migration[5.1]
  def up
    execute "ALTER TABLE `allocator_prefixes` DROP PRIMARY KEY"
    add_index :allocator_prefixes, [:allocator, :prefixes], unique: true
    add_column :allocator_prefixes, :id, :primary_key
    add_column :allocator_prefixes, :created, :datetime
    add_column :allocator_prefixes, :updated, :datetime

    execute "ALTER TABLE `datacentre_prefixes` DROP PRIMARY KEY"
    add_index :datacentre_prefixes, [:datacentre, :prefixes], unique: true
    add_column :datacentre_prefixes, :id, :primary_key
    add_column :datacentre_prefixes, :created, :datetime
    add_column :datacentre_prefixes, :updated, :datetime
  end

  def down
    remove_index :allocator_prefixes, name: "index_allocator_prefixes_on_allocator_and_prefixes"
    remove_column :allocator_prefixes, :id
    remove_column :allocator_prefixes, :created
    remove_column :allocator_prefixes, :updated
    execute "ALTER TABLE `allocator_prefixes` ADD PRIMARY KEY (allocator,prefixes);"

    remove_index :datacentre_prefixes, name: "index_datacentre_prefixes_on_datacentre_and_prefixes"
    remove_column :datacentre_prefixes, :id
    remove_column :datacentre_prefixes, :created
    remove_column :datacentre_prefixes, :updated
    execute "ALTER TABLE `datacentre_prefixes` ADD PRIMARY KEY (datacentre,prefixes);"
  end
end
