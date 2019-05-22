class RemoveGeneralContact < ActiveRecord::Migration[5.2]
    def up
        remove_column :allocator, :general_contact
    end

    def down
        add_column :allocator, :general_contact, :json
    end
end
