# frozen_string_literal: true
class AddResearchersTable < ActiveRecord::Migration[5.2]
  def up
    create_table "researchers", force: :cascade do |t|
      t.string   "name",                 limit: 191
      t.string   "family_name",          limit: 191
      t.string   "given_names",          limit: 191
      t.string   "email",                limit: 191
      t.string   "provider",             limit: 255,   default: "orcid"
      t.string   "uid",                  limit: 191
      t.string   "authentication_token", limit: 191
      t.string   "role_id",              limit: 255,   default: "user"
      t.boolean  "auto_update",                        default: true
      t.datetime "expires_at",                         default: '1970-01-01 00:00:00', null: false
      t.datetime "created_at",           precision: 3
      t.datetime "updated_at",           precision: 3
      t.text     "other_names",          limit: 65535
      t.string   "confirmation_token",   limit: 191
      t.datetime "confirmed_at"
      t.datetime "confirmation_sent_at"
      t.string   "unconfirmed_email",    limit: 255
      t.string   "github",               limit: 191
      t.string   "github_uid",           limit: 191
      t.string   "github_token",         limit: 191
      t.string   "google_uid",           limit: 191
      t.string   "google_token",         limit: 191
      t.integer  "github_put_code",      limit: 4
      t.boolean  "is_public",                          default: true
      t.boolean  "beta_tester",                        default: false
    end
  
    add_index "researchers", ["uid"], name: "index_researchers_on_uid", unique: true, using: :btree
  end

  def down
    drop_table :researchers
  end
end
