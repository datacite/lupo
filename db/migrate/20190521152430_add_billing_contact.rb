class AddBillingContact < ActiveRecord::Migration[5.2]
  def up
    add_column :allocator, :billing_contact, :json
  end

  def down
    remove_column :allocator, :billing_contact
  end
end
