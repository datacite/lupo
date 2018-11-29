class AddLandingPageToDataset < ActiveRecord::Migration[5.2]
  def change
    add_column :dataset, :landing_page, :json
  end
end
