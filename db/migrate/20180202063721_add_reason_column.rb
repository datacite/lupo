# frozen_string_literal: true

class AddReasonColumn < ActiveRecord::Migration[5.1]
  def change
    add_column :dataset, :reason, :string
  end
end
