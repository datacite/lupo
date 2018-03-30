class AddInstitutionTypeColumn < ActiveRecord::Migration[5.1]
  def up
    add_column :allocator, :joined, :date
    remove_column :allocator, :year, :integer
    change_column :allocator, :description, :text, limit: 65535

    add_column :allocator, :institution_type, :string, limit: 191
    add_index :allocator, [:institution_type], name: "index_member_institution_type"
  end

  def down
    remove_column :allocator, :joined, :date
    remove_column :allocator, :institution_type, :string, limit: 191

    add_column :allocator, :year, :integer
    change_column :allocator, :description, :string
  end
end
