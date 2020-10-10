# frozen_string_literal: true

class AddTypeToDoi < ActiveRecord::Migration[5.2]
  def up
    add_column :dataset, :type, :string, limit: 16
    change_column_default :dataset, :type, "DataCiteDoi"
    change_column_default :dataset, :agency, "datacite"
  end

  def down
    remove_column :dataset, :type
    change_column_default :dataset, :agency, "DataCite"
  end
end
