# frozen_string_literal: true

class RenameConsortumLeadIdColumn < ActiveRecord::Migration[5.2]
  def change
    rename_column :allocator, :consortium_lead_id, :consortium_id
  end
end
