# frozen_string_literal: true

class AddPublisherObjToDoi < ActiveRecord::Migration[6.1]
  def up
    add_column :dataset, :publisher_obj, :json
  end

  def down
    remove_column :dataset, :publisher_obj
  end
end
