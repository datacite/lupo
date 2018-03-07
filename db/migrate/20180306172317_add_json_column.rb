class AddJsonColumn < ActiveRecord::Migration[5.1]
  def change
    add_column :dataset, :crosscite, :text, limit: 16777215
  end
end
