# frozen_string_literal: true

require 'lhm'

class AddEventsProperties < ActiveRecord::Migration[5.2]
  def up
    Lhm.change_table :events do |m|
      m.add_column :source_doi, "TEXT"
      m.add_column :target_doi, "TEXT"
      m.add_column :source_relation_type_id, "VARCHAR(191)"
      m.add_column :target_relation_type_id, "VARCHAR(191)"
      m.add_index ["source_doi(100)", "source_relation_type_id(191)"], :index_events_on_source_doi
      m.add_index ["target_doi(100)", "target_relation_type_id(191)"], :index_events_on_target_doi
    end
  end

  def down
    Lhm.change_table :events do |m|
      m.remove_index ["target_doi(100)", "target_relation_type_id(191)"], :index_events_on_target_doi
      m.remove_index ["source_doi(100)", "source_relation_type_id(191)"], :index_events_on_source_doi
      m.remove_column :target_relation_type_id
      m.remove_column :source_relation_type_id
      m.remove_column :target_doi
      m.remove_column :source_doi
    end
  end
end
