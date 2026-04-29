  class AddCoveringIndexToEnrichments < ActiveRecord::Migration[7.2]
    disable_departure!

    def change
      add_index :enrichments,
        [:updated_at, :id],
        order: { updated_at: :desc, id: :desc },
        name: "index_enrichments_on_updated_at_and_id"
    end
  end
