# frozen_string_literal: true

class AddMissingIndexesToAllocator < ActiveRecord::Migration[6.1]
  def change
    add_index :allocator, :deleted_at, name: 'index_allocator_deleted_at'
    add_index :allocator, :role_name, name: 'index_allocator_role_name'
  end
end
