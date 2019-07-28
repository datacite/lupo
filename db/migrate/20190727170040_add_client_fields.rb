class AddClientFields < ActiveRecord::Migration[5.2]
  def change
    remove_index :datacentre, [:re3data]
    rename_column :datacentre, :re3data, :re3data_id
    add_index :datacentre, [:re3data_id]

    add_column :datacentre, :issn, :json
    add_column :datacentre, :certificate, :json
    add_column :datacentre, :repository_type, :json
    add_column :datacentre, :alternate_name, :string, limit: 191
    add_column :datacentre, :language, :string, limit: 191
    add_column :datacentre, :opendoar_id, :integer
  end
end
