class CreateAllocatorPrefixes < ActiveRecord::Migration[5.1]
  def change
    create_table :allocator_prefixes do |t|
      t.belongs_to :allocator, index: true
      t.belongs_to :prefix, index: true
    end
  end
end
