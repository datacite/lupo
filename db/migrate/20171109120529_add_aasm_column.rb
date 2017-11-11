class AddAasmColumn < ActiveRecord::Migration[5.1]
  def self.up
    add_column :dataset, :state, :string, default: "new"
    add_index :dataset, [:state]
  end

  def self.down
    remove_column :dataset, :state
  end
end
