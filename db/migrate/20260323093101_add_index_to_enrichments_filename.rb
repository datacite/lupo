class AddIndexToEnrichmentsFilename < ActiveRecord::Migration[7.2]
  disable_departure!

  def change
    add_index :enrichments, :filename
  end
end
