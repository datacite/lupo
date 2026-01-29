class CreateEnrichments < ActiveRecord::Migration[7.2]
  disable_departure!

  def change
    create_table :enrichments, options: "DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci" do |t|
      t.string :doi, null: false
      t.json :contributors, null: false
      t.json :resources, null: false
      t.string :field, null: false
      t.string :action, null: false
      t.json :original_value, null: true
      t.json :enriched_value, null: true

      t.timestamps
    end

    add_index :enrichments, [:doi, :updated_at, :id], order: { updated_at: :desc, id: :desc }
  end
end
