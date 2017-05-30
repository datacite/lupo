class DatacentresPrefixes < ActiveRecord::Migration[5.1]
  def change
    create_table :datacentre_prefixes, id: false do |t|
      t.belongs_to :datacentre, index: true
      t.belongs_to :prefix, index: true
    end
  end
end
