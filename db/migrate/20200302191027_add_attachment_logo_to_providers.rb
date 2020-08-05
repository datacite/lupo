class AddAttachmentLogoToProviders < ActiveRecord::Migration[5.2]
  def self.up
    change_table :allocator do |t|
      t.attachment :logo
    end
  end

  def self.down
    remove_attachment :allocator, :logo
  end
end
