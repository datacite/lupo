# frozen_string_literal: true

class AddJsonColumn < ActiveRecord::Migration[5.1]
  def change
    add_column :dataset, :crosscite, :text, limit: 16_777_215
  end
end
