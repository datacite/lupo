class AddColumnTypeToAllocator < ActiveRecord::Migration[5.1]
  def change
    remove_column :allocator, :member_type, :string
    add_column :allocator, :provider_type, :string
  end
end
