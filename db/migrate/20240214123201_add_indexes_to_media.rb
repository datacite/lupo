# frozen_string_literal: true

class AddIndexesToMedia < ActiveRecord::Migration[6.1]
  def change
    add_index :media, [:dataset, :created], name: "index_media_dataset_created"
  end
end
