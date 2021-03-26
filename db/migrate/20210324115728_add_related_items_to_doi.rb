# frozen_string_literal: true

class AddRelatedItemsToDoi < ActiveRecord::Migration[5.2]
  def up
    add_column :dataset, :related_items, :json
  end

  def down
    remove_column :dataset, :related_items
  end
end
