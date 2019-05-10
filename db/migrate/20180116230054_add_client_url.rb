# frozen_string_literal: true

class AddClientUrl < ActiveRecord::Migration[5.1]
  def change
    add_column :datacentre, :url, :text, limit: 65535
    add_index :datacentre, :url, name: "index_datacentre_on_url", length: 100
  end
end
