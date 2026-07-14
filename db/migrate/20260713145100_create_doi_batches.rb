class CreateDoiBatches < ActiveRecord::Migration[7.2]
  disable_departure!

  def change
    create_table :doi_batches, options: "DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci" do |t|
      t.string :uuid, null: false
      t.string :operation, null: false
      t.string :status, null: false, default: "queued"
      t.string :submitted_by, null: false
      t.string :role_id, null: false
      t.string :client_id
      t.string :provider_id
      t.integer :total_count, null: false, default: 0
      t.integer :succeeded_count, null: false, default: 0
      t.integer :failed_count, null: false, default: 0
      t.datetime :started_at
      t.datetime :completed_at

      t.timestamps
    end

    add_index :doi_batches, :uuid, unique: true
    add_index :doi_batches, [:client_id, :created_at]
    add_index :doi_batches, [:provider_id, :created_at]
    add_index :doi_batches, [:submitted_by, :created_at]

    create_table :doi_batch_items, options: "DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci" do |t|
      t.references :doi_batch, null: false, foreign_key: true
      t.integer :position, null: false
      t.string :doi
      t.boolean :generated_doi, null: false, default: false
      t.json :payload, null: false
      t.string :status, null: false, default: "queued"
      t.integer :response_status
      t.json :result_errors
      t.datetime :started_at
      t.datetime :completed_at

      t.timestamps
    end

    add_index :doi_batch_items, [:doi_batch_id, :position], unique: true
    add_index :doi_batch_items, [:doi_batch_id, :status, :position],
      name: "index_doi_batch_items_on_batch_status_position"
  end
end
