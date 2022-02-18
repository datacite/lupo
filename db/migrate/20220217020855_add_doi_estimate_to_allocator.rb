class AddDoiEstimateToAllocator < ActiveRecord::Migration[5.2]
  def change
    add_column :allocator, :doi_estimate_year_one, :integer, default: 0, null: false
  end


  def self.down
    remove_column :doi_estimate_year_one
  end
end
