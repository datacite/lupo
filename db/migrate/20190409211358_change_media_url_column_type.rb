class ChangeMediaUrlColumnType < ActiveRecord::Migration[5.2]
  def up
    change_column :media, :url, :text, limit: 65535
    add_index :media, :url, name: 'index_media_on_url', length: 100
  end

  def down
    remove_index :media, name: "index_media_on_url", column: :url
    change_column :media, :url, :string
  end
end
