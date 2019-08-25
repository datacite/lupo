# frozen_string_literal: true

class AddBillingContact < ActiveRecord::Migration[5.2]
  def up
    add_column :allocator, :billing_contact, :json
    add_column :allocator, :secondary_billing_contact, :json
  end

  def down
    remove_column :allocator, :billing_contact
    remove_column :allocator, :secondary_billing_contact
  end
end
