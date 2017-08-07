class CreateAllocators < ActiveRecord::Migration[5.1]
  def change
    create_table :allocator do |t|
      t.string :comments
      t.string :contact_email
      t.string :contact_name
      t.datetime :created
      t.integer :doi_quota_allowed
      t.integer :doi_quota_used
      t.binary :is_active
      t.string :name
      t.string :password
      t.string :role_name
      t.string :symbol
      t.datetime :updated
      t.integer :version
      t.string :experiments

      t.timestamps
    end
  end
end
