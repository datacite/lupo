class DatacentresPrefixes < ActiveRecord::Migration[5.1]
  def change
    create_table :datacentre_prefixes do |t|
      t.belongs_to :datacentre, index: true
      t.belongs_to :prefix, index: true
    end
    rename_column :datacentre_prefixes, :datacentre_id, :datacentre
    rename_column :datacentre_prefixes, :prefix_id, :prefixes
  end
end
