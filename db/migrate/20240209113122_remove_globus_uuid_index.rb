# frozen_string_literal: true

class RemoveGlobusUuidIndex < ActiveRecord::Migration[6.1]
  def change
    remove_index :allocator, column: :globus_uuid
  end
end
