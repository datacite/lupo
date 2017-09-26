class AddUrlIndex < ActiveRecord::Migration[5.1]
  def change
    add_column :dataset, :last_landing_page, :string
    add_column :dataset, :last_landing_page_content_type, :string
    add_index :dataset, [:url]
  end
end
