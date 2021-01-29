# frozen_string_literal: true

class AddContactModel < ActiveRecord::Migration[5.2]
  def change
    create_table "contacts", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
      t.string "uid", limit: 36
      t.bigint "provider_id", null: false
      t.string "given_name"
      t.string "family_name"
      t.string "email"
      t.json "role_name"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.datetime "deleted_at"
    end
  end
end
