# frozen_string_literal: true

class Addre3dataColumn < ActiveRecord::Migration[5.1]
  def change
    add_column :datacentre, :re3data, :string
    add_index :datacentre, %i[re3data]
  end
end
