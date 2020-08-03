# frozen_string_literal: true

class AddTypeToDoi < ActiveRecord::Migration[5.2]
  def up
    remove_foreign_key "dataset", "datacentre"
    add_column :dataset, :type, :string, limit: 16
    change_column_default :dataset, :type, "DataCiteDoi"
    add_index :dataset, [:type], name: "index_dataset_on_type", length: { type: 16 }
    change_column_default :dataset, :agency, "datacite"
  end

  def down
    remove_column :dataset, :type
    change_column_default :dataset, :agency, "DataCite"
  end
end
