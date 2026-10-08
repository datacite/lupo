# frozen_string_literal: true

class AddEventToEnrichments < ActiveRecord::Migration[7.2]
  disable_departure!

  def change
    add_column :enrichments, :event, :string, null: true
  end
end
