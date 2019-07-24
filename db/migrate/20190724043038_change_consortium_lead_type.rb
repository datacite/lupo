class ChangeConsortiumLeadType < ActiveRecord::Migration[5.2]
  def self.up
    change_column :allocator, :consortium_lead_id, :integer
  end
 
  def self.down
    change_column :allocator, :consortium_lead_id, :string
  end
end
