# frozen_string_literal: true

class AddExtraProviderContacts < ActiveRecord::Migration[5.2]
  def up
    add_column :allocator, :general_contact, :json
    add_column :allocator, :technical_contact, :json
    add_column :allocator, :service_contact, :json
    add_column :allocator, :voting_contact, :json
  end

  def down
    remove_column :allocator, :general_contact
    remove_column :allocator, :technical_contact
    remove_column :allocator, :service_contact
    remove_column :allocator, :voting_contact
  end
end
