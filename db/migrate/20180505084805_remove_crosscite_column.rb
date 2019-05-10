# frozen_string_literal: true

class RemoveCrossciteColumn < ActiveRecord::Migration[5.2]
  def change
    remove_column :dataset, :from, :string
    remove_column :dataset, :crosscite, :text, limit: 16777215
  end
end
