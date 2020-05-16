# frozen_string_literal: true

class AddAllocatorPrefixesColumn < ActiveRecord::Migration[5.1]
  def change
    add_column :datacentre_prefixes, :allocator_prefixes, :integer, limit: 8
    add_index :datacentre_prefixes, [:allocator_prefixes]
    safety_assured { rename_column :datacentre_prefixes, :created, :created_at }
    safety_assured { rename_column :datacentre_prefixes, :updated, :updated_at }
    safety_assured { rename_column :allocator_prefixes, :created, :created_at }
    safety_assured { rename_column :allocator_prefixes, :updated, :updated_at }
  end
end
