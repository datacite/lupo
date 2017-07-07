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

ActiveRecord::Schema.define(version: 20170613131615) do

  create_table "allocator", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4" do |t|
    t.string "comments"
    t.string "contact_email"
    t.string "contact_name"
    t.datetime "created"
    t.integer "doi_quota_allowed"
    t.integer "doi_quota_used"
    t.binary "is_active"
    t.string "name"
    t.string "password"
    t.string "role_name"
    t.string "symbol"
    t.datetime "updated"
    t.integer "version"
    t.string "experiments"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "allocator_prefixes", id: false, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4" do |t|
    t.bigint "allocator"
    t.bigint "prefixes"
    t.index ["allocator"], name: "index_allocator_prefixes_on_allocator"
    t.index ["prefixes"], name: "index_allocator_prefixes_on_prefixes"
  end

  create_table "datacentre", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4" do |t|
    t.bigint "allocator_id"
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
    t.bigint "allocator"
    t.string "experiments"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["allocator_id"], name: "index_datacentre_on_allocator_id"
  end

  create_table "datacentre_prefixes", id: false, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4" do |t|
    t.bigint "datacentre"
    t.bigint "prefixes"
    t.index ["datacentre"], name: "index_datacentre_prefixes_on_datacentre"
    t.index ["prefixes"], name: "index_datacentre_prefixes_on_prefixes"
  end

  create_table "dataset", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4" do |t|
    t.bigint "datacentre_id"
    t.datetime "created"
    t.string "doi"
    t.binary "is_active"
    t.binary "is_ref_quality"
    t.integer "last_landing_page_status"
    t.datetime "last_landing_page_status_check"
    t.string "last_metadata_status"
    t.datetime "updated"
    t.integer "version"
    t.bigint "datacentre"
    t.datetime "minted"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["datacentre_id"], name: "index_dataset_on_datacentre_id"
  end

  create_table "prefix", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4" do |t|
    t.datetime "created"
    t.string "prefix"
    t.integer "version"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

end
