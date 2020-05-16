class AddOtherDoisTable < ActiveRecord::Migration[5.2]
  def up
    create_table "other_dois", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
      t.datetime "created_at"
      t.string "doi", null: false
      t.boolean "is_active", default: true
      t.integer "last_landing_page_status"
      t.datetime "last_landing_page_status_check"
      t.json "last_landing_page_status_result"
      t.string "last_metadata_status"
      t.datetime "updated_at"
      t.bigint "repository_id"
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
      t.string "version", limit: 191
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
      t.index ["aasm_state"], name: "index_dois_on_aasm_state"
      t.index ["created_at", "indexed", "updated_at"], name: "index_dataset_on_created_indexed_updated"
      t.index ["doi"], name: "doi", unique: true
      t.index ["last_landing_page_content_type"], name: "index_dois_on_last_landing_page_content_type"
      t.index ["last_landing_page_status"], name: "index_dois_on_last_landing_page_status"
      t.index ["repository_id"], name: "FK5605B47847B5F5FF"
      t.index ["schema_version"], name: "index_dois_on_schema_version"
      t.index ["source"], name: "index_dataset_source"
      t.index ["url"], name: "index_dois_on_url", length: 100
    end
  end

  def down
    drop_table :other_dois
  end
end
