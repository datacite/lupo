# frozen_string_literal: true

class AddSourceColumn < ActiveRecord::Migration[5.2]
  def change
    add_column :dataset, :source, :string, limit: 191
    add_index :dataset, [:source], name: "index_dataset_source"
  end
end
