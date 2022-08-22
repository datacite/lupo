class AddSubjectsToDatacentre < ActiveRecord::Migration[6.1]
  def change
    add_column :datacentre, :subjects, :json
  end
end
