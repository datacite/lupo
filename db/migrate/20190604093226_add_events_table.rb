# frozen_string_literal: true

class AddEventsTable < ActiveRecord::Migration[5.2]
  def change
    create_table "events",
                 options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4",
                 force: :cascade do |t|
      t.text "uuid", null: false
      t.text "subj_id", null: false
      t.text "obj_id"
      t.string "source_id", limit: 191
      t.string "aasm_state"
      t.string "state_event"
      t.text "callback"
      t.text "error_messages"
      t.text "source_token"
      t.datetime "created_at", precision: 3, null: false
      t.datetime "updated_at", precision: 3, null: false
      t.datetime "indexed_at", default: "1970-01-01 00:00:00", null: false
      t.datetime "occurred_at"
      t.string "message_action", limit: 191, default: "create", null: false
      t.string "relation_type_id", limit: 191
      t.text "subj", limit: 16_777_215
      t.text "obj", limit: 16_777_215
      t.integer "total", default: 1
      t.string "license", limit: 191
      t.index %w[created_at indexed_at updated_at],
              name: "index_events_on_created_indexed_updated"
      t.index %w[source_id created_at],
              name: "index_events_on_source_id_created_at"
      t.index %w[subj_id obj_id source_id relation_type_id],
              name: "index_events_on_multiple_columns",
              unique: true,
              length: { subj_id: 191, obj_id: 191 }
      t.index %w[updated_at], name: "index_events_on_updated_at"
      t.index %w[uuid], name: "index_events_on_uuid", unique: true, length: 36
    end
  end
end
