# frozen_string_literal: true

class AddGlobusUuid < ActiveRecord::Migration[5.2]
  def change
    add_column :datacentre, :globus_uuid, :string, limit: 191
    add_column :allocator, :globus_uuid, :string, limit: 191

    add_index :datacentre,
              %i[globus_uuid],
              name: "index_datacentre_on_globus_uuid",
              length: { globus_uuid: 191 }
    add_index :allocator,
              %i[globus_uuid],
              name: "index_allocator_on_globus_uuid",
              length: { globus_uuid: 191 }
  end
end
