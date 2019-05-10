# frozen_string_literal: true

class AddSchemaAttributes < ActiveRecord::Migration[5.2]
  def change
    add_column :dataset, :creator, :json
    add_column :dataset, :contributor, :json
    add_column :dataset, :titles, :json
    add_column :dataset, :publisher, :text
    add_column :dataset, :publication_year, :integer
    add_column :dataset, :types, :json
    add_column :dataset, :descriptions, :json
    add_column :dataset, :periodical, :json
    add_column :dataset, :sizes, :json
    add_column :dataset, :formats, :json
    add_column :dataset, :version_info, :string, limit: 191
    add_column :dataset, :language, :string, limit: 191
    add_column :dataset, :dates, :json
    add_column :dataset, :alternate_identifiers, :json
    add_column :dataset, :related_identifiers, :json
    add_column :dataset, :funding_references, :json
    add_column :dataset, :geo_locations, :json
    add_column :dataset, :rights_list, :json
    add_column :dataset, :subjects, :json
    add_column :dataset, :schema_version, :string, limit: 191
    add_column :dataset, :content_url, :json
    add_column :dataset, :xml, :binary, limit: 16777215
  end
end
