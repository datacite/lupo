# frozen_string_literal: true

class AddFromColumn < ActiveRecord::Migration[5.2]
  def change
    add_column :dataset, :from, :string
  end
end
