# frozen_string_literal: true

class RemoveResourcesFromEnrichments < ActiveRecord::Migration[7.2]
  disable_departure!

  def change
    remove_column :enrichments, :resources, :json, null: false
  end
end
