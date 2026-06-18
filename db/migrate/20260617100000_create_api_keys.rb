class CreateApiKeys < ActiveRecord::Migration[7.2]
  def change
    create_table :api_keys, id: false do |t|
      t.string :id, limit: 36, primary_key: true
      t.bigint :client_id, null: false
      t.string :name, null: false, limit: 191
      t.string :key_prefix, null: false, limit: 32
      t.string :key_hash, null: false, limit: 191
      t.datetime :last_used_at
      t.datetime :revoked_at
      t.timestamps
    end

    add_index :api_keys, :client_id
    add_index :api_keys, :key_prefix, unique: true
    add_index :api_keys, :revoked_at
  end
end
