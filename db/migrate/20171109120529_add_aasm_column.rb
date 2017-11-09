class AddAasmColumn < ActiveRecord::Migration[5.1]
  def self.up
    add_column :dataset, :aasm_state, :integer
    add_index :dataset, [:aasm_state]
  end

  def self.down
    remove_column :dataset, :aasm_state
  end
end
