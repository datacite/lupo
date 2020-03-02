class AddAttachmentLogoToProviders < ActiveRecord::Migration[5.2]
  def self.up
    safety_assured do
      change_table :allocator do |t|
        t.attachment :logo
      end
    end
  end

  def self.down
    safety_assured do
      remove_attachment :allocator, :logo
    end
  end
end
