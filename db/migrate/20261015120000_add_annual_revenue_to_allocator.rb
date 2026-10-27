# frozen_string_literal: true

class AddAnnualRevenueToAllocator < ActiveRecord::Migration[7.2]
  def change
    add_column :allocator, :annual_revenue, :string, limit: 191
  end
end
