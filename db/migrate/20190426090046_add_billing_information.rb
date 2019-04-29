class AddBillingInformation < ActiveRecord::Migration[5.2]
  def up
    add_column :allocator, :billing_information, :json
    add_column :allocator, :twitter_handle, :string, limit: 20
    add_column :allocator, :ror_id, :string
  end

  def down
    remove_column :allocator, :billing_information
    remove_column :allocator, :twitter_handle
    remove_column :allocator, :ror_id
  end
end
