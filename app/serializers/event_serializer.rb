
class EventSerializer
  include FastJsonapi::ObjectSerializer
  # include BatchLoaderHelper

  set_key_transform :camel_lower
  set_type :events
  set_id :uuid
  
  attributes :subj_id, :obj_id, :source_id, :source_doi, :target_doi, :relation_type_id, :source_relation_type_id, :target_relation_type_id, :total, :message_action, :source_token, :license, :occurred_at, :timestamp

  attribute :timestamp, &:updated_at

  belongs_to :doi_for_source, record_type: :doi, id_method_name: :source_doi, serializer: DoiSerializer
  belongs_to :doi_for_target, record_type: :doi, id_method_name: :target_doi, serializer: DoiSerializer
end
