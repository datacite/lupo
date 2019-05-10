# frozen_string_literal: true

class RenameDoiColumns < ActiveRecord::Migration[5.2]
  def change
    rename_column :dataset, :alternate_identifiers, :identifiers
    rename_column :dataset, :periodical, :container
  end
end
