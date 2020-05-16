# frozen_string_literal: true

class ChangeUrlColumnType < ActiveRecord::Migration[5.1]
  def up
    remove_index :dataset, name: "index_dataset_on_url", column: :url
    safety_assured { change_column :dataset, :url, :text, limit: 65535 }
    add_index :dataset, :url, name: "index_dataset_on_url", length: 100
  end

  def down
    remove_index :dataset, name: "index_dataset_on_url", column: :url
    change_column :dataset, :url, :string
    add_index :dataset, :url, name: "index_dataset_on_url"
  end
end
