class ChangeForeignKeyTypeDatacentre < ActiveRecord::Migration[5.1]
  def up
    change_column :datacentre, :allocator, :bigint
  end

  def down
    change_column :datacentre, :allocator, :bigint
  end

  def up
    change_column :dataset, :datacentre, :bigint
  end

  def down
    change_column :dataset, :datacentre, :bigint
  end
end
