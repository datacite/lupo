# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_06_17_100000) do
  create_table "active_storage_attachments", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", limit: 191, null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum", limit: 191
    t.string "content_type", limit: 191
    t.datetime "created_at", null: false
    t.string "filename", limit: 191, null: false
    t.string "key", limit: 191, null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "allocator", charset: "utf8mb3", force: :cascade do |t|
    t.json "billing_contact"
    t.json "billing_information"
    t.text "comments", size: :long
    t.string "consortium_id"
    t.string "country_code"
    t.datetime "created"
    t.datetime "deleted_at"
    t.text "description"
    t.string "display_name"
    t.integer "doi_estimate", default: 0, null: false
    t.integer "doi_quota_allowed", null: false
    t.integer "doi_quota_used", null: false
    t.string "experiments"
    t.string "focus_area", limit: 191
    t.string "globus_uuid", limit: 191
    t.string "group_email"
    t.binary "is_active", limit: 1
    t.date "joined"
    t.string "logo"
    t.string "logo_content_type"
    t.string "logo_file_name"
    t.bigint "logo_file_size"
    t.datetime "logo_updated_at"
    t.string "name", null: false
    t.string "non_profit_status", limit: 191
    t.string "organization_type", limit: 191
    t.string "password"
    t.string "region"
    t.string "role_name"
    t.string "ror_id"
    t.string "salesforce_id", limit: 191
    t.json "secondary_billing_contact"
    t.json "secondary_service_contact"
    t.json "secondary_technical_contact"
    t.json "service_contact"
    t.string "symbol", null: false
    t.string "system_email", null: false
    t.json "technical_contact"
    t.string "twitter_handle", limit: 20
    t.datetime "updated"
    t.integer "version"
    t.json "voting_contact"
    t.string "website"
    t.index ["deleted_at"], name: "index_allocator_deleted_at"
    t.index ["organization_type"], name: "index_allocator_organization_type"
    t.index ["role_name"], name: "index_allocator_role_name"
    t.index ["ror_id"], name: "index_allocator_ror_id"
    t.index ["symbol"], name: "symbol", unique: true
  end

  create_table "api_keys", id: { type: :string, limit: 36 }, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "client_id", null: false
    t.datetime "created_at", null: false
    t.string "key_hash", limit: 191, null: false
    t.string "key_prefix", limit: 32, null: false
    t.datetime "last_used_at"
    t.string "name", limit: 191, null: false
    t.datetime "revoked_at"
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_api_keys_on_client_id"
    t.index ["key_prefix"], name: "index_api_keys_on_key_prefix", unique: true
    t.index ["revoked_at"], name: "index_api_keys_on_revoked_at"
  end

  create_table "audits", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "action"
    t.integer "associated_id"
    t.string "associated_type"
    t.integer "auditable_id"
    t.string "auditable_type"
    t.json "audited_changes"
    t.string "comment"
    t.datetime "created_at", precision: 3
    t.string "remote_address"
    t.string "request_uuid"
    t.integer "user_id"
    t.string "user_type"
    t.string "username"
    t.integer "version", default: 0
    t.index ["associated_type", "associated_id"], name: "associated_index"
    t.index ["auditable_type", "auditable_id", "version"], name: "auditable_index"
    t.index ["created_at"], name: "index_audits_on_created_at"
    t.index ["request_uuid"], name: "index_audits_on_request_uuid"
    t.index ["user_id", "user_type"], name: "user_index"
  end

  create_table "client_prefixes", charset: "utf8mb3", force: :cascade do |t|
    t.bigint "client_id", null: false
    t.datetime "created_at"
    t.bigint "prefix_id", null: false
    t.bigint "provider_prefix_id"
    t.string "uid", null: false
    t.datetime "updated_at"
    t.index ["client_id"], name: "FK13A1B3BA47B5F5FF"
    t.index ["prefix_id"], name: "FK13A1B3BAAF86A1C7"
    t.index ["provider_prefix_id"], name: "index_client_prefixes_on_provider_prefix_id"
    t.index ["uid"], name: "index_client_prefixes_on_uid", length: 128
  end

  create_table "contacts", charset: "utf8mb3", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "deleted_at"
    t.string "email"
    t.string "family_name"
    t.string "given_name"
    t.bigint "provider_id", null: false
    t.json "role_name"
    t.string "uid", limit: 36
    t.datetime "updated_at"
    t.index ["deleted_at"], name: "index_contacts_deleted_at"
    t.index ["email"], name: "index_contacts_email"
    t.index ["uid"], name: "index_contacts_uid"
  end

  create_table "datacentre", charset: "utf8mb3", force: :cascade do |t|
    t.bigint "allocator", null: false
    t.string "alternate_name", limit: 191
    t.text "analytics_dashboard_url"
    t.string "analytics_tracking_id"
    t.json "certificate"
    t.string "client_type", limit: 191
    t.text "comments", size: :long
    t.datetime "created"
    t.datetime "deleted_at"
    t.text "description"
    t.integer "doi_quota_allowed", null: false
    t.integer "doi_quota_used", null: false
    t.text "domains"
    t.string "experiments"
    t.string "globus_uuid", limit: 191
    t.binary "is_active", limit: 1
    t.json "issn"
    t.json "language"
    t.string "name", null: false
    t.integer "opendoar_id"
    t.string "password"
    t.string "re3data_id"
    t.json "repository_type"
    t.string "role_name"
    t.string "salesforce_id", limit: 191
    t.json "service_contact"
    t.string "software", limit: 191
    t.json "subjects"
    t.string "symbol", null: false
    t.string "system_email", null: false
    t.datetime "updated"
    t.text "url"
    t.integer "version"
    t.index ["allocator"], name: "FK6695D60546EBD781"
    t.index ["globus_uuid"], name: "index_datacentre_on_globus_uuid"
    t.index ["re3data_id"], name: "index_datacentre_on_re3data_id"
    t.index ["symbol"], name: "symbol", unique: true
    t.index ["url"], name: "index_datacentre_on_url", length: 100
  end

  create_table "dataset", charset: "utf8mb3", force: :cascade do |t|
    t.string "aasm_state"
    t.string "agency", limit: 191, default: "datacite"
    t.json "container"
    t.json "content_url"
    t.json "contributors"
    t.datetime "created"
    t.json "creators"
    t.bigint "datacentre", null: false
    t.json "dates"
    t.json "descriptions"
    t.string "doi", null: false
    t.json "formats"
    t.json "funding_references"
    t.json "geo_locations"
    t.json "identifiers"
    t.datetime "indexed", precision: 3, default: "1970-01-01 00:00:00", null: false
    t.binary "is_active", limit: 1, null: false
    t.binary "is_ref_quality", limit: 1
    t.json "landing_page"
    t.string "language", limit: 191
    t.text "last_landing_page"
    t.string "last_landing_page_content_type"
    t.integer "last_landing_page_status"
    t.datetime "last_landing_page_status_check"
    t.json "last_landing_page_status_result"
    t.string "last_metadata_status"
    t.datetime "minted"
    t.integer "publication_year"
    t.json "publisher_obj"
    t.string "reason"
    t.json "related_identifiers"
    t.json "related_items"
    t.json "rights_list"
    t.string "schema_version", limit: 191
    t.json "sizes"
    t.string "source", limit: 191
    t.json "subjects"
    t.json "titles"
    t.string "type", limit: 16, default: "DataCiteDoi"
    t.json "types"
    t.datetime "updated"
    t.text "url"
    t.integer "version"
    t.string "version_info", limit: 191
    t.binary "xml", size: :medium
    t.index ["aasm_state"], name: "index_dataset_on_aasm_state"
    t.index ["created", "indexed", "updated"], name: "index_dataset_on_created_indexed_updated"
    t.index ["datacentre"], name: "FK5605B47847B5F5FF"
    t.index ["doi"], name: "doi", unique: true
    t.index ["last_landing_page_content_type"], name: "index_dataset_on_last_landing_page_content_type"
    t.index ["last_landing_page_status"], name: "index_dataset_on_last_landing_page_status"
    t.index ["schema_version"], name: "index_dataset_on_schema_version"
    t.index ["source"], name: "index_dataset_source"
    t.index ["type"], name: "index_dataset_on_type"
    t.index ["url"], name: "index_dataset_on_url", length: 100
  end

  create_table "enrichments", charset: "utf8mb3", force: :cascade do |t|
    t.string "action", null: false
    t.json "contributors", null: false
    t.datetime "created_at", null: false
    t.string "doi", null: false
    t.json "enriched_value"
    t.string "field", null: false
    t.string "filename"
    t.json "original_value"
    t.json "resources", null: false
    t.string "source_id", null: false
    t.datetime "updated_at", null: false
    t.string "uuid", limit: 36, null: false
    t.index ["doi", "updated_at", "id"], name: "index_enrichments_on_doi_and_updated_at_and_id", order: { updated_at: :desc, id: :desc }
    t.index ["field"], name: "index_enrichments_on_field"
    t.index ["filename"], name: "index_enrichments_on_filename"
    t.index ["updated_at", "id"], name: "index_enrichments_on_updated_at_and_id", order: :desc
    t.index ["uuid"], name: "index_enrichments_on_uuid", unique: true
  end

  create_table "events", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "aasm_state"
    t.text "callback"
    t.datetime "created_at", precision: 3, null: false
    t.text "error_messages"
    t.datetime "indexed_at", default: "1970-01-01 00:00:00", null: false
    t.string "license", limit: 191
    t.string "message_action", limit: 191, default: "create", null: false
    t.text "obj", size: :medium
    t.text "obj_id"
    t.datetime "occurred_at"
    t.string "relation_type_id", limit: 191
    t.text "source_doi"
    t.string "source_id", limit: 191
    t.string "source_relation_type_id", limit: 191
    t.text "source_token"
    t.string "state_event"
    t.text "subj", size: :medium
    t.text "subj_id", null: false
    t.text "target_doi"
    t.string "target_relation_type_id", limit: 191
    t.integer "total", default: 1
    t.datetime "updated_at", precision: 3, null: false
    t.text "uuid", null: false
    t.index ["created_at", "indexed_at", "updated_at"], name: "index_events_on_created_indexed_updated"
    t.index ["source_doi", "source_relation_type_id"], name: "index_events_on_source_doi", length: { source_doi: 100 }
    t.index ["source_id", "created_at"], name: "index_events_on_source_id_created_at"
    t.index ["subj_id", "obj_id", "source_id", "relation_type_id"], name: "index_events_on_multiple_columns", unique: true, length: { subj_id: 191, obj_id: 191 }
    t.index ["target_doi", "target_relation_type_id"], name: "index_events_on_target_doi", length: { target_doi: 100 }
    t.index ["updated_at"], name: "index_events_on_updated_at"
    t.index ["uuid"], name: "index_events_on_uuid", unique: true, length: 36
  end

  create_table "media", charset: "utf8mb3", force: :cascade do |t|
    t.datetime "created"
    t.bigint "dataset", null: false
    t.string "media_type", limit: 80
    t.datetime "updated"
    t.text "url", null: false
    t.integer "version"
    t.index ["dataset", "created"], name: "index_media_dataset_created"
    t.index ["dataset", "updated"], name: "dataset_updated"
    t.index ["dataset"], name: "FK62F6FE44D3D6B1B"
    t.index ["url"], name: "index_media_on_url", length: 100
  end

  create_table "metadata", charset: "utf8mb3", force: :cascade do |t|
    t.datetime "created"
    t.bigint "dataset", null: false
    t.binary "is_converted_by_mds", limit: 1
    t.integer "metadata_version"
    t.string "namespace"
    t.integer "version"
    t.binary "xml", size: :medium
    t.index ["dataset", "created"], name: "index_metadata_dataset_created"
    t.index ["dataset", "metadata_version"], name: "dataset_version"
    t.index ["dataset"], name: "FKE52D7B2F4D3D6B1B"
  end

  create_table "prefixes", charset: "utf8mb3", force: :cascade do |t|
    t.datetime "created_at"
    t.string "uid", limit: 80, null: false
    t.index ["uid"], name: "prefix", unique: true
  end

  create_table "provider_prefixes", charset: "utf8mb3", force: :cascade do |t|
    t.datetime "created_at"
    t.bigint "prefix_id", null: false
    t.bigint "provider_id", null: false
    t.string "uid", null: false
    t.datetime "updated_at"
    t.index ["prefix_id"], name: "FKE7FBD674AF86A1C7"
    t.index ["provider_id"], name: "FKE7FBD67446EBD781"
    t.index ["uid"], name: "index_provider_prefixes_on_uid", length: 128
  end

  create_table "reference_repositories", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "client_id"
    t.datetime "created_at", null: false
    t.string "re3doi"
    t.datetime "updated_at", null: false
  end

  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
end
