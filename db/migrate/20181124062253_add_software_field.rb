# frozen_string_literal: true

class AddSoftwareField < ActiveRecord::Migration[5.2]
  def change
    add_column :datacentre, :software, :string, limit: 191
    add_column :datacentre, :description, :text
  end
end
