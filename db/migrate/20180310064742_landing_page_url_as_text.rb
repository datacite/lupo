class LandingPageUrlAsText < ActiveRecord::Migration[5.1]
  def up
    change_column :dataset, :last_landing_page, :text, limit: 65535
    add_index :dataset, :last_landing_page, name: 'index_dataset_on_last_landing_page', length: 100
  end

  def down
    remove_index :dataset, name: "index_dataset_on_last_landing_page", column: :last_landing_page
    change_column :dataset, :last_landing_page, :string
  end
end
