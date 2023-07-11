# frozen_string_literal: true

class CreateDataDumps < ActiveRecord::Migration[6.1]
  def change
    create_table :data_dumps do |t|
      t.string :uid, null: false
      t.string :scope, null: false
      t.text :description
      t.datetime :start_date, null: false
      t.datetime :end_date, null: false
      t.bigint :records
      t.string :checksum
      t.string :file_path
      t.string :aasm_state

      t.timestamps

      t.index %w[uid], { name: "index_data_dumps_on_uid", unique: true }
      t.index %w[updated_at], name: "index_data_dumps_on_updated_at"
      t.index %w[scope], name: "index_data_dumps_on_scope"
      t.index %w[aasm_state], name: "index_data_dumps_on_aasm_state"
    end
  end
end
