class CreateDatacentres < ActiveRecord::Migration[5.1]
  def change
    create_table :datacentre do |t|
      t.belongs_to :allocator, index: true
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
      t.bigint :allocator
      t.string :experiments

      t.timestamps
    end
    # rename_column :datacentre, :allocator_id, :allocator
  end
end
