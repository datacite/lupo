class CreateResolutionReports < ActiveRecord::Migration[8.0]
  def change
    create_table :resolution_reports, id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci" do |t|
      t.string :period, limit: 7, null: false # Format: "YYYY-MM"
      t.string :prefix, limit: 80, null: false
      t.integer :total_attempted_resolutions, unsigned: true, null: false, default: 0
      t.integer :successful_resolutions, unsigned: true, null: false, default: 0
      t.integer :failed_resolutions, unsigned: true, null: false, default: 0
      t.integer :total_unique_dois, unsigned: true, null: false, default: 0
      t.integer :unique_doi_successes, unsigned: true, null: false, default: 0
      t.integer :unique_doi_failures, unsigned: true, null: false, default: 0

      t.timestamp :created_at, null: false, default: -> { "CURRENT_TIMESTAMP" }

      t.index [:period, :prefix], unique: true, name: "idx_period_prefix"
      t.index [:prefix, :period], name: "idx_prefix_period"

    end
  end
end
