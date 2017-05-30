class CreateDatasets < ActiveRecord::Migration[5.1]
  def change
    create_table :dataset do |t|
      t.belongs_to :datacentre, index: true
      t.datetime :created
      t.string :doi
      t.binary :is_active
      t.binary :is_ref_quality
      t.integer :last_landing_page_status
      t.datetime :last_landing_page_status_check
      t.string :last_metadata_status
      t.datetime :updated
      t.integer :version
      t.integer :datacentre
      t.datetime :minted

      t.timestamps
    end
  end
end
