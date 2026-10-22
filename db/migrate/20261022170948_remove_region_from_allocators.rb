class RemoveRegionFromAllocators < ActiveRecord::Migration[8.1]
  disable_departure!

  def change
    remove_column :allocator, :region, :string
  end
end
