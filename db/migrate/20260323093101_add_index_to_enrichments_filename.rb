class AddIndexToEnrichmentsFilename < ActiveRecord::Migration[7.2]
  def change
    add_index :enrichments, :filename
  end
end
