# frozen_string_literal: true

class AddDeletedAtColumn < ActiveRecord::Migration[5.1]
  def change
    add_column :allocator, :deleted_at, :datetime, default: nil
    add_column :datacentre, :deleted_at, :datetime, default: nil
  end
end
