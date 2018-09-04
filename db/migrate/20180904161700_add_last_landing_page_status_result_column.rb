class AddLastLandingPageStatusResultColumn < ActiveRecord::Migration[5.2]
  def change
    add_column :dataset, :last_landing_page_status_result, :json, :after => :last_landing_page_status_check
  end
end
