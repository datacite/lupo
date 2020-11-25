# frozen_string_literal: true

class SchemaVersionIndex < ActiveRecord::Migration[5.2]
  def change
    add_index :dataset, %i[schema_version]
  end
end
