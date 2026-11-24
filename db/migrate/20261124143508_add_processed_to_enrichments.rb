# frozen_string_literal: true

class AddProcessedToEnrichments < ActiveRecord::Migration[7.2]
  disable_departure!

  def up
    # Existing rows are filled with the column default (true) when the column is added.
    add_column :enrichments, :processed, :boolean, null: false, default: true
    # New rows should default to false going forward.
    change_column_default :enrichments, :processed, from: true, to: false
  end

  def down
    remove_column :enrichments, :processed
  end
end
