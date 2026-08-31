# frozen_string_literal: true

class RemoveContributorsFromEnrichments < ActiveRecord::Migration[7.2]
  disable_departure!

  def change
    remove_column :enrichments, :contributors, :json, null: false
  end
end
