class RenameVersionInfoColumn < ActiveRecord::Migration[5.2]
  def up
    Lhm.change_table :dois do |m|
      m.rename_column :version_info, :version
    end
  end

  def down
    Lhm.change_table :dois do |m|
      m.rename_column :version, :version_info 
    end
  end
end
