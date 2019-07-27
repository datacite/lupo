class AddClientTypeColumn < ActiveRecord::Migration[5.2]
  def change
    add_column :datacentre, :client_type, :string, limit: 191
  end
end
