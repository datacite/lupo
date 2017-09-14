class ConvertToHasManyThrough < ActiveRecord::Migration[5.1]
  def up
    execute "ALTER TABLE `allocator_prefixes` DROP PRIMARY KEY"
    add_column :allocator_prefixes, :id, :primary_key
    add_column :allocator_prefixes, :created, :datetime
    add_column :allocator_prefixes, :updated, :datetime

    execute "ALTER TABLE `datacentre_prefixes` DROP PRIMARY KEY"
    add_column :datacentre_prefixes, :id, :primary_key
    add_column :datacentre_prefixes, :created, :datetime
    add_column :datacentre_prefixes, :updated, :datetime
  end

  def down
    remove_column :allocator_prefixes, :id
    remove_column :allocator_prefixes, :created
    remove_column :allocator_prefixes, :updated
    execute "ALTER TABLE `allocator_prefixes` ADD PRIMARY KEY (allocator,prefixes);"

    remove_column :datacentre_prefixes, :id
    remove_column :datacentre_prefixes, :created
    remove_column :datacentre_prefixes, :updated
    execute "ALTER TABLE `datacentre_prefixes` ADD PRIMARY KEY (datacentre,prefixes);"
  end
end
