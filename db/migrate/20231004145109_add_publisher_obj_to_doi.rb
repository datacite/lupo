class AddPublisherObjToDoi < ActiveRecord::Migration[6.1]
  def up
    add_column :dataset, :publisher_obj, :json
  end

  def down
    remove_column :dataset, :related_items
  end
end
