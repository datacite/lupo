class AddConsortiumLeadId < ActiveRecord::Migration[5.2]
  def change
    add_column :allocator, :consortium_lead_id, :string
  end
end
