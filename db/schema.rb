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

ActiveRecord::Schema.define(version: 2019_05_22_162430) do

  create_table "active_storage_attachments", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin", force: :cascade do |t|
    t.string "name", limit: 191, null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin", force: :cascade do |t|
    t.string "key", limit: 191, null: false
    t.string "filename", limit: 191, null: false
    t.string "content_type", limit: 191
    t.text "metadata"
    t.bigint "byte_size", null: false
    t.string "checksum", limit: 191, null: false
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "allocator", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
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
    t.text "description"
    t.string "region"
    t.string "country_code"
    t.string "website"
    t.string "phone"
    t.datetime "deleted_at"
    t.date "joined"
    t.string "logo"
    t.string "focus_area", limit: 191
    t.string "organization_type", limit: 191
    t.json "billing_information"
    t.string "twitter_handle", limit: 20
    t.string "ror_id"
    t.json "technical_contact"
    t.json "service_contact"
    t.json "voting_contact"
    t.json "billing_contact"
    t.json "secondary_billing_contact"
    t.index ["organization_type"], name: "index_allocator_organization_type"
    t.index ["symbol"], name: "symbol", unique: true
  end

  create_table "allocator_prefixes", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "allocator", null: false
    t.bigint "prefixes", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["allocator", "prefixes"], name: "index_allocator_prefixes_on_allocator_and_prefixes", unique: true
    t.index ["allocator"], name: "FKE7FBD67446EBD781"
    t.index ["prefixes"], name: "FKE7FBD674AF86A1C7"
  end

  create_table "audits", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin", force: :cascade do |t|
    t.integer "auditable_id"
    t.string "auditable_type"
    t.integer "associated_id"
    t.string "associated_type"
    t.integer "user_id"
    t.string "user_type"
    t.string "username"
    t.string "action"
    t.json "audited_changes"
    t.integer "version", default: 0
    t.string "comment"
    t.string "remote_address"
    t.string "request_uuid"
    t.datetime "created_at", precision: 3
    t.index ["associated_type", "associated_id"], name: "associated_index"
    t.index ["auditable_type", "auditable_id", "version"], name: "auditable_index"
    t.index ["created_at"], name: "index_audits_on_created_at"
    t.index ["request_uuid"], name: "index_audits_on_request_uuid"
    t.index ["user_id", "user_type"], name: "user_index"
  end

  create_table "datacentre", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
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
    t.string "software", limit: 191
    t.text "description"
    t.index ["allocator"], name: "FK6695D60546EBD781"
    t.index ["re3data"], name: "index_datacentre_on_re3data"
    t.index ["symbol"], name: "symbol", unique: true
    t.index ["url"], name: "index_datacentre_on_url", length: 100
  end

  create_table "datacentre_prefixes", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
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

  create_table "dataset", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.datetime "created"
    t.string "doi", null: false
    t.binary "is_active", limit: 1, null: false
    t.binary "is_ref_quality", limit: 1
    t.integer "last_landing_page_status"
    t.datetime "last_landing_page_status_check"
    t.json "last_landing_page_status_result"
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
    t.string "source", limit: 191
    t.datetime "indexed", precision: 3, default: "1970-01-01 00:00:00", null: false
    t.json "creators"
    t.json "contributors"
    t.json "titles"
    t.text "publisher"
    t.integer "publication_year"
    t.json "types"
    t.json "descriptions"
    t.json "container"
    t.json "sizes"
    t.json "formats"
    t.string "version_info", limit: 191
    t.string "language", limit: 191
    t.json "dates"
    t.json "identifiers"
    t.json "related_identifiers"
    t.json "funding_references"
    t.json "geo_locations"
    t.json "rights_list"
    t.json "subjects"
    t.string "schema_version", limit: 191
    t.json "content_url"
    t.binary "xml", limit: 16777215
    t.json "landing_page"
    t.string "agency", limit: 191, default: "DataCite"
    t.index ["aasm_state"], name: "index_dataset_on_aasm_state"
    t.index ["created", "indexed", "updated"], name: "index_dataset_on_created_indexed_updated"
    t.index ["datacentre"], name: "FK5605B47847B5F5FF"
    t.index ["doi"], name: "doi", unique: true
    t.index ["last_landing_page_content_type"], name: "index_dataset_on_last_landing_page_content_type"
    t.index ["last_landing_page_status"], name: "index_dataset_on_last_landing_page_status"
    t.index ["schema_version"], name: "index_dataset_on_schema_version"
    t.index ["source"], name: "index_dataset_source"
    t.index ["url"], name: "index_dataset_on_url", length: 100
  end

  create_table "media", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.datetime "created"
    t.string "media_type", limit: 80
    t.datetime "updated"
    t.text "url", null: false
    t.integer "version"
    t.bigint "dataset", null: false
    t.index ["dataset", "updated"], name: "dataset_updated"
    t.index ["dataset"], name: "FK62F6FE44D3D6B1B"
    t.index ["url"], name: "index_media_on_url", length: 100
  end

  create_table "metadata", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
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

  create_table "prefix", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
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
