class RenameStateColumn < ActiveRecord::Migration[5.1]
  def change
    rename_column :dataset, :state, :aasm_state
    change_column_default :dataset, :aasm_state, :nil
  end
end
