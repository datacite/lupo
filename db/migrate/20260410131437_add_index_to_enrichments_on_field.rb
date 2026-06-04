class AddIndexToEnrichmentsOnField < ActiveRecord::Migration[7.2]
  disable_departure!

  def change
    add_index :enrichments, :field, name: "index_enrichments_on_field"
  end
end
