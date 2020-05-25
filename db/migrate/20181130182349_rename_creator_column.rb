# frozen_string_literal: true

class RenameCreatorColumn < ActiveRecord::Migration[5.2]
  def change
    rename_column :dataset, :creator, :creators
    rename_column :dataset, :contributor, :contributors
    add_column :dataset, :agency, :string, limit: 191, default: "DataCite"
  end
end
