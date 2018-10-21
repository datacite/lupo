class RemoveMicrosecondsInTimeColumns < ActiveRecord::Migration[5.2]
  def up
    change_column :dataset, :created, :datetime
    change_column :dataset, :updated, :datetime
  end
  def down
    change_column :dataset, :created, :datetime, limit: 3
    change_column :dataset, :updated, :datetime, limit: 3
  end
end
