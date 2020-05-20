# frozen_string_literal: true

class MicrosecondsInTimeColumns < ActiveRecord::Migration[5.2]
  def up
    safety_assured { add_column :dataset, :indexed, :datetime, limit: 3, default: "1970-01-01 00:00:00", null: false }
    add_index "dataset", ["created", "indexed", "updated"], name: "index_dataset_on_created_indexed_updated"
  end

  def down
    remove_index :dataset, column: ["created", "indexed", "updated"], name: "index_dataset_on_created_indexed_updated"
    remove_column :dataset, :indexed
  end
end
