class AddSalesforceIdColumn < ActiveRecord::Migration[5.2]
  def change
    add_column :datacentre, :salesforce_id, :string, limit: 191
    add_column :allocator, :salesforce_id, :string, limit: 191

    rename_column :datacentre, :contact_email, :system_email
    remove_column :datacentre, :contact_name, :string, limit: 191

    add_column :datacentre, :service_contact, :json

    add_column :allocator, :non_profit_status, :string, limit: 191
  end
end
