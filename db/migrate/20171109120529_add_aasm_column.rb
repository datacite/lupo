# frozen_string_literal: true

class AddAasmColumn < ActiveRecord::Migration[5.1]
  def self.up
    add_column :dataset, :state, :string, default: "draft"
    add_index :dataset, %i[state]
  end

  def self.down
    remove_column :dataset, :state
  end
end
