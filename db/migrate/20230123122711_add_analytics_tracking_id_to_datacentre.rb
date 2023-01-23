class AddAnalyticsTrackingIdToDatacentre < ActiveRecord::Migration[6.1]
  def change
    add_column :datacentre, :analytics_tracking_id, :string, after: :analytics_dashboard_url
  end
end
