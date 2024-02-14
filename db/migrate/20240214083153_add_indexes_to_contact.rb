class AddIndexesToContact < ActiveRecord::Migration[6.1]
  def change
    add_index :contacts, :uid, name: "index_contacts_uid"
    add_index :contacts, :email, name: "index_contacts_email"
    add_index :contacts, :deleted_at, name: "index_contacts_deleted_at"
  end
end
