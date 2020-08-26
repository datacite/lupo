class AddAgencyIndex < ActiveRecord::Migration[5.2]
  def up
    add_index :dataset, [:type], name: "index_dataset_on_type", length: { type: 16 }
  end

  def down
    remove_index :dataset, name: "index_dataset_on_type"
  end
end
