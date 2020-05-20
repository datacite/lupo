# frozen_string_literal: true

class RemoveGeneralContact < ActiveRecord::Migration[5.2]
  def up
    safety_assured { remove_column :allocator, :general_contact }
  end

  def down
    add_column :allocator, :general_contact, :json
  end
end
