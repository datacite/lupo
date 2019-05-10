# frozen_string_literal: true

class AddFocusArea < ActiveRecord::Migration[5.2]
  def up
    remove_column :allocator, :institution_type, :string, limit: 191

    add_column :allocator, :focus_area, :string, limit: 191
    add_column :allocator, :organization_type, :string, limit: 191
    add_index :allocator, [:organization_type], name: "index_allocator_organization_type"
  end

  def down
    add_column :allocator, :institution_type, :string, limit: 191
    add_index :allocator, [:institution_type], name: "index_member_institution_type"

    remove_column :allocator, :focus_area, :string, limit: 191
    remove_column :allocator, :organization_type, :string, limit: 191
  end
end
