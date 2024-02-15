class AddIndexesToMetadata < ActiveRecord::Migration[6.1]
  def change
    add_index :metadata, [:dataset, :created], name: "index_metadata_dataset_created"
  end
end
