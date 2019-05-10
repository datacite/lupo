# frozen_string_literal: true

class ChangeColumnInTables < ActiveRecord::Migration[5.1]
  def change
    add_column :dataset, :url, :string
  end
end
