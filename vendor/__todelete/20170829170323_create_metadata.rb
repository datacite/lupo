class CreateMetadata < ActiveRecord::Migration[5.1]
  def change
    create_table :metadata do |t|
      t.datetime :created
      t.integer :verion
      t.integer :metadata_version
      t.integer :dataset
      t.binary :is_converted_by_mds
      t.string :namespace
      t.text :xml

      t.timestamps
    end
  end
end
