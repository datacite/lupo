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

ActiveRecord::Schema.define(version: 20180310064742) do

  create_table "allocator", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 ROW_FORMAT=COMPACT" do |t|
    t.string "contact_email", null: false
    t.string "contact_name", limit: 80, null: false
    t.datetime "created"
    t.integer "doi_quota_allowed", null: false
    t.integer "doi_quota_used", null: false
    t.binary "is_active", limit: 1
    t.string "name", null: false
    t.string "password"
    t.string "role_name"
    t.string "symbol", null: false
    t.datetime "updated"
    t.integer "version"
    t.text "comments", limit: 4294967295
    t.string "experiments"
    t.string "description"
    t.integer "year"
    t.string "region"
    t.string "country_code"
    t.string "website"
    t.string "phone"
    t.datetime "deleted_at"
    t.index ["symbol"], name: "symbol", unique: true
  end

  create_table "allocator_prefixes", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 ROW_FORMAT=COMPACT" do |t|
    t.bigint "allocator", null: false
    t.bigint "prefixes", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["allocator", "prefixes"], name: "index_allocator_prefixes_on_allocator_and_prefixes", unique: true
    t.index ["allocator"], name: "FKE7FBD67446EBD781"
    t.index ["prefixes"], name: "FKE7FBD674AF86A1C7"
  end

  create_table "datacentre", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 ROW_FORMAT=COMPACT" do |t|
    t.text "comments", limit: 4294967295
    t.string "contact_email", null: false
    t.string "contact_name", limit: 80, null: false
    t.datetime "created"
    t.integer "doi_quota_allowed", null: false
    t.integer "doi_quota_used", null: false
    t.string "domains"
    t.binary "is_active", limit: 1
    t.string "name", null: false
    t.string "password"
    t.string "role_name"
    t.string "symbol", null: false
    t.datetime "updated"
    t.integer "version"
    t.bigint "allocator", null: false
    t.string "experiments"
    t.datetime "deleted_at"
    t.string "re3data"
    t.text "url"
    t.index ["allocator"], name: "FK6695D60546EBD781"
    t.index ["re3data"], name: "index_datacentre_on_re3data"
    t.index ["symbol"], name: "symbol", unique: true
    t.index ["url"], name: "index_datacentre_on_url", length: { url: 100 }
  end

  create_table "datacentre_prefixes", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 ROW_FORMAT=COMPACT" do |t|
    t.bigint "datacentre", null: false
    t.bigint "prefixes", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.bigint "allocator_prefixes"
    t.index ["allocator_prefixes"], name: "index_datacentre_prefixes_on_allocator_prefixes"
    t.index ["datacentre", "prefixes"], name: "index_datacentre_prefixes_on_datacentre_and_prefixes", unique: true
    t.index ["datacentre"], name: "FK13A1B3BA47B5F5FF"
    t.index ["prefixes"], name: "FK13A1B3BAAF86A1C7"
  end

  create_table "dataset", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 ROW_FORMAT=COMPACT" do |t|
    t.datetime "created"
    t.string "doi", null: false
    t.binary "is_active", limit: 1, null: false
    t.binary "is_ref_quality", limit: 1
    t.integer "last_landing_page_status"
    t.datetime "last_landing_page_status_check"
    t.string "last_metadata_status"
    t.datetime "updated"
    t.integer "version"
    t.bigint "datacentre", null: false
    t.datetime "minted"
    t.text "url"
    t.text "last_landing_page"
    t.string "last_landing_page_content_type"
    t.string "aasm_state"
    t.string "reason"
    t.text "crosscite", limit: 16777215
    t.index ["aasm_state"], name: "index_dataset_on_aasm_state"
    t.index ["datacentre"], name: "FK5605B47847B5F5FF"
    t.index ["doi"], name: "doi", unique: true
    t.index ["last_landing_page"], name: "index_dataset_on_last_landing_page", length: { last_landing_page: 100 }
    t.index ["url"], name: "index_dataset_on_url", length: { url: 100 }
  end

  create_table "media", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 ROW_FORMAT=COMPACT" do |t|
    t.datetime "created"
    t.string "media_type", limit: 80
    t.datetime "updated"
    t.string "url", null: false
    t.integer "version"
    t.bigint "dataset", null: false
    t.index ["dataset", "updated"], name: "dataset_updated"
    t.index ["dataset"], name: "FK62F6FE44D3D6B1B"
  end

  create_table "metadata", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 ROW_FORMAT=COMPACT" do |t|
    t.datetime "created"
    t.integer "metadata_version"
    t.integer "version"
    t.binary "xml", limit: 16777215
    t.bigint "dataset", null: false
    t.binary "is_converted_by_mds", limit: 1
    t.string "namespace"
    t.index ["dataset", "metadata_version"], name: "dataset_version"
    t.index ["dataset"], name: "FKE52D7B2F4D3D6B1B"
  end

  create_table "prefix", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 ROW_FORMAT=COMPACT" do |t|
    t.datetime "created"
    t.string "prefix", limit: 80, null: false
    t.integer "version"
    t.datetime "updated"
    t.index ["prefix"], name: "prefix", unique: true
  end

  add_foreign_key "allocator_prefixes", "allocator", column: "allocator", name: "FKE7FBD67446EBD781"
  add_foreign_key "allocator_prefixes", "prefix", column: "prefixes", name: "FKE7FBD674AF86A1C7"
  add_foreign_key "datacentre", "allocator", column: "allocator", name: "FK6695D60546EBD781"
  add_foreign_key "datacentre_prefixes", "datacentre", column: "datacentre", name: "FK13A1B3BA47B5F5FF"
  add_foreign_key "datacentre_prefixes", "prefix", column: "prefixes", name: "FK13A1B3BAAF86A1C7"
  add_foreign_key "dataset", "datacentre", column: "datacentre", name: "FK5605B47847B5F5FF"
  add_foreign_key "media", "dataset", column: "dataset", name: "FK62F6FE44D3D6B1B"
  add_foreign_key "metadata", "dataset", column: "dataset", name: "FKE52D7B2F4D3D6B1B"
end
