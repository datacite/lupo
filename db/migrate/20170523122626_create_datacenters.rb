class CreateDatacenters < ActiveRecord::Migration[5.1]
  def change
    create_table :datacenters do |t|
      t.string :comments
      t.string :contact_email
      t.string :contact_name
      t.datetime :created
      t.integer :doi_quota_allowed
      t.integer :doi_quota_used
      t.string :domains
      t.binary :is_active
      t.string :name
      t.string :password
      t.string :role_name
      t.string :symbol
      t.datetime :updated
      t.integer :version
      t.integer :allocator
      t.string :experiments

      t.timestamps
    end
  end
end
