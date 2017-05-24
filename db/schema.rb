# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20170523122626) do

  create_table "datacenters", force: :cascade do |t|
    t.string "comments"
    t.string "contact_email"
    t.string "contact_name"
    t.datetime "created"
    t.integer "doi_quota_allowed"
    t.integer "doi_quota_used"
    t.string "domains"
    t.binary "is_active"
    t.string "name"
    t.string "password"
    t.string "role_name"
    t.string "symbol"
    t.datetime "updated"
    t.integer "version"
    t.integer "allocator"
    t.string "experiments"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

end
