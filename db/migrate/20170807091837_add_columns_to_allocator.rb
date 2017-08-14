class AddColumnsToAllocator < ActiveRecord::Migration[5.1]
  def change
    add_column :allocator, :description, :string
    add_column :allocator, :year, :integer
    add_column :allocator, :region, :string
    add_column :allocator, :country_code, :string
    add_column :allocator, :website, :string
    add_column :allocator, :phone, :string

    add_column :prefix, :updated, :datetime
  end
end
