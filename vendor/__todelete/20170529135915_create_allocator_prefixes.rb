class CreateAllocatorPrefixes < ActiveRecord::Migration[5.1]
  def change
    create_table :allocator_prefixes, id: false do |t|
      t.belongs_to :allocator, index: true
      t.belongs_to :prefix, index: true
    end
    rename_column :allocator_prefixes, :allocator_id, :allocator
    rename_column :allocator_prefixes, :prefix_id, :prefixes
  end
end
