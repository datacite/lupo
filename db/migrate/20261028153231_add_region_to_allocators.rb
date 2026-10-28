class AddRegionToAllocators < ActiveRecord::Migration[8.1]
  disable_departure!

  def change
    add_column :allocator, :region, :string
  end
end
