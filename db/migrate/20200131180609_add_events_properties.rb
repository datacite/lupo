# frozen_string_literal: true

class AddEventsProperties < ActiveRecord::Migration[5.2]
  def up
    add_column :events, :source_doi, :text
    add_column :events, :target_doi, :text
    add_column :events, :source_relation_type_id, :string, limit: 191
    add_column :events, :target_relation_type_id, :string, limit: 191
    add_index :events,
              %i[source_doi source_relation_type_id],
              name: "index_events_on_source_doi", length: { source_doi: 100 }
    add_index :events,
              %i[target_doi target_relation_type_id],
              name: "index_events_on_target_doi", length: { target_doi: 100 }
  end

  def down
    remove_column :events, :source_doi
    remove_column :events, :target_doi
    remove_column :events, :source_relation_type_id
    remove_column :events, :target_relation_type_id
  end
end
