# frozen_string_literal: true

class AddAnalyticsSlugToDatacentre < ActiveRecord::Migration[5.2]
  def change
    add_column :datacentre, :analytics_slug, :string
  end
end
