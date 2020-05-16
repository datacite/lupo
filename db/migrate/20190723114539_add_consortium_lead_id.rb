# frozen_string_literal: true

class AddConsortiumLeadId < ActiveRecord::Migration[5.2]
  def change
    add_column :allocator, :consortium_id, :string
  end
end
