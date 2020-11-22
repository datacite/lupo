# frozen_string_literal: true

class LandingPageUrlAsText < ActiveRecord::Migration[5.1]
  def up
    change_column :dataset, :last_landing_page, :text, limit: 65_535
    add_index :dataset,
              :last_landing_page_status,
              name: "index_dataset_on_last_landing_page_status"
    add_index :dataset,
              :last_landing_page_content_type,
              name: "index_dataset_on_last_landing_page_content_type"
  end

  def down
    remove_index :dataset,
                 name: "index_dataset_on_last_landing_page_status",
                 column: :last_landing_page_status
    remove_index :dataset,
                 name: "index_dataset_on_last_landing_page_content_type",
                 column: :last_landing_page_content_type
    change_column :dataset, :last_landing_page, :string
  end
end
