# frozen_string_literal: true

class AddIndexesToMetadata < ActiveRecord::Migration[6.1]
  disable_departure!

  def change
    add_index :metadata, [:dataset, :created], name: "index_metadata_dataset_created"
  end
end
