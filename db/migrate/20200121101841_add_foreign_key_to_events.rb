# frozen_string_literal: true

class AddForeignKeyToEvents < ActiveRecord::Migration[5.2]
  def change
    add_column :events, :doi_id, :text
    add_index :events, [:doi_id, :relation_type_id], name: "index_events_on_doi_id", length: { doi_id: 100, relation_type_id: 191 }
  end
end
