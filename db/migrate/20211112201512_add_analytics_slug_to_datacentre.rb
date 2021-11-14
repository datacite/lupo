class AddAnalyticsSlugToDatacentre < ActiveRecord::Migration[5.2]
  def change
    add_column :datacentre, :analytics_slug, :string
  end
end
