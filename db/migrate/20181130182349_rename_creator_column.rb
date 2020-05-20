# frozen_string_literal: true

class RenameCreatorColumn < ActiveRecord::Migration[5.2]
  def up
    safety_assured { rename_column :dataset, :creator, :creators }
    safety_assured { rename_column :dataset, :contributor, :contributors }
    add_column :dataset, :agency, :string, limit: 191
    change_column_default :dataset, :agency, "DataCite"
  end

  def down
    remove_column :dataset, :agency, :string, limit: 191
    safety_assured { rename_column :dataset, :contributors, :contributor }
    safety_assured { rename_column :dataset, :creators, :creator }
  end
end
