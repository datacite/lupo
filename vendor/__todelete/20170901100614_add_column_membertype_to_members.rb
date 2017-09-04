class AddColumnMembertypeToMembers < ActiveRecord::Migration[5.1]
  def change
    add_column :allocator, :member_type, :string
  end
end
