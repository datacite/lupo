class RemoveGeneralContactPhone < ActiveRecord::Migration[5.2]
  def up
    remove_column :allocator, :contact_name
    remove_column :allocator, :phone

    add_column :allocator, :display_name, :string
    add_column :allocator, :group_email, :string
    add_column :allocator, :secondary_service_contact, :json
    add_column :allocator, :secondary_technical_contact, :json
    rename_column :allocator, :contact_email, :system_email
  end

  def down
    remove_column :allocator, :display_name
    remove_column :allocator, :group_email
    remove_column :allocator, :secondary_service_contact
    remove_column :allocator, :secondary_technical_contact

    add_column :allocator, :contact_name, :string, limit: 80, null: false
    add_column :allocator, :phone, :string

    rename_column :allocator, :system_email, :contact_email
  end
end
