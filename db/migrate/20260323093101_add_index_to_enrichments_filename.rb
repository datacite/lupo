class AddIndexToEnrichmentsFilename < ActiveRecord::Migration[7.2]
  disable_departure!

  INDEX_NAME = "index_enrichments_on_filename"

  def up
    if mysql?
      execute <<~SQL
        ALTER TABLE `enrichments`
        ADD INDEX `#{INDEX_NAME}` (`filename`)
      SQL
    else
      add_index :enrichments, :filename, name: INDEX_NAME
    end
  end

  def down
    if mysql?
      execute <<~SQL
        ALTER TABLE `enrichments`
        DROP INDEX `#{INDEX_NAME}`
      SQL
    else
      remove_index :enrichments, name: INDEX_NAME
    end
  end

  private

  def mysql?
    ActiveRecord::Base.connection.adapter_name.to_s.downcase.include?("mysql")
  end
end
