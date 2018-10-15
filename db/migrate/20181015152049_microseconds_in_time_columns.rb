class MicrosecondsInTimeColumns < ActiveRecord::Migration[5.2]
  def up
    change_column :dataset, :created, :datetime, limit: 3
    change_column :dataset, :updated, :datetime, limit: 3

    add_column :dataset, :indexed, :datetime, limit: 3, default: '1970-01-01 00:00:00', null: false
    add_index "dataset", ["created", "indexed", "updated"], name: "index_dataset_on_created_indexed_updated"
  end

  def down
    remove_index :dataset, column: ["created", "indexed", "updated"], name: "index_dataset_on_created_indexed_updated"
    remove_column :dataset, :indexed

    change_column :dataset, :created, :datetime
    change_column :dataset, :updated, :datetime
  end
end
