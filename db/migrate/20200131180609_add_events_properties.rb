class AddEventsProperties < ActiveRecord::Migration[5.2]
  def change
    add_column :events, :source_id, :text
    add_column :events, :target_id, :text
    add_column :events, :source_relation_type_id, :string, limit: 191
    add_column :events, :target_relation_type_id, :string, limit: 191
    add_index :events, [:source_id, :source_relation_type_id], name: "index_events_on_source_id", length: { source_id: 100, source_relation_type_id: 191 }
    add_index :events, [:target_id, :target_relation_type_id], name: "index_events_on_target_id", length: { target_id: 100, target_relation_type_id: 191 }
  end
end
