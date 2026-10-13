# frozen_string_literal: true

class AddContentKeyToEnrichments < ActiveRecord::Migration[7.2]
  disable_departure!

  def change
    add_column :enrichments, :content_key, :string, null: true
    add_index :enrichments, :content_key, name: "index_enrichments_on_content_key"
  end
end
