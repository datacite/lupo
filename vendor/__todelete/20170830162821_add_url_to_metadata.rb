class AddUrlToMetadata < ActiveRecord::Migration[5.1]
  def change
    add_column :metadata, :url, :string
  end
end
