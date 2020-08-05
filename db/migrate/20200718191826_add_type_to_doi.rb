require 'lhm'

class AddTypeToDoi < ActiveRecord::Migration[5.2]
  def up
    remove_foreign_key "dataset", "datacentre"
    Lhm.change_table :dataset do |m|
      m.change_column :agency, "VARCHAR(16) DEFAULT 'datacite'"
      m.add_column :type, "VARCHAR(16) NOT NULL DEFAULT 'DataciteDoi'"
      m.add_index ["type(16)"], :index_dataset_on_type
    end
  end

  def down
    Lhm.change_table :dataset do |m|
      m.change_column :agency, "VARCHAR(191) DEFAULT 'DataCite'"
      m.remove_column :type
    end
  end
end
