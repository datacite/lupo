class RenameStateColumn < ActiveRecord::Migration[5.1]
  def self.up
    remove_column :dataset, :state
    add_column :dataset, :aasm_state, :string
    add_index :dataset, [:aasm_state]
  end

  def self.down
    remove_column :dataset, :aasm_state
    add_column :dataset, :state, :string, default: "draft"
    add_index :dataset, [:state]
  end
end
