# frozen_string_literal: true

class RemovePublisherFieldFromDoi < ActiveRecord::Migration[6.1]
  def change
    remove_column :dataset, :publisher, :string
  end
end
