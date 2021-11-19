# frozen_string_literal: true

class AddAnalyticsDashboardUrlToDatacentre < ActiveRecord::Migration[5.2]
  def change
    add_column :datacentre, :analytics_dashboard_url, :text
  end
end
