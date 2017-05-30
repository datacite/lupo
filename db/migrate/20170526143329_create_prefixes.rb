class CreatePrefixes < ActiveRecord::Migration[5.1]
  def change
    create_table :prefix do |t|
      t.datetime :created
      t.string :prefix
      t.integer :version

      t.timestamps
    end
  end
end
