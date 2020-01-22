class AddGlobusUuid < ActiveRecord::Migration[5.2]
  def change
    add_column :datacentre, :globus_uuid, :string, limit: 191
    add_column :allocator, :globus_uuid, :string, limit: 191

    add_index :datacentre, [:globus_uuid], name: "index_datacentre_on_globus_uuid", length: { globus_uuid: 191 }
    add_index :allocator, [:globus_uuid], name: "index_allocator_on_globus_uuid", length: { globus_uuid: 191 }
  end
end
