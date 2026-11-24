# frozen_string_literal: true

class AddProcessedDoiIndexToEnrichments < ActiveRecord::Migration[7.2]
  disable_departure!

  def change
    add_index :enrichments,
      [:processed, :doi],
      name: "index_enrichments_on_processed_and_doi"
  end
end
