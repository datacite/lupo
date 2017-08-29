class CreateMedia < ActiveRecord::Migration[5.1]
  def change
    create_table :media do |t|
      t.datetime :created
      t.datetime :updated
      t.integer :dataset
      t.integer :version
      t.string :url
      t.string :media_type

      t.timestamps
    end
  end
end
