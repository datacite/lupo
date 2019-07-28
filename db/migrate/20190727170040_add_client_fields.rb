class AddClientFields < ActiveRecord::Migration[5.2]
  def change
    change_column_default :datacentre, :client_type, from: nil, to: "repository"

    add_column :datacentre, :issn, :json
    add_column :datacentre, :certificate, :json
    add_column :datacentre, :alternate_name, :string, limit: 191
    add_column :datacentre, :language, :string, limit: 191
  end
end
