class OldEventSerializer
  include FastJsonapi::ObjectSerializer
  set_key_transform :dash
  set_type :events
  set_id :uuid
  
  attributes :subj_id, :obj_id, :source_id, :relation_type_id, :total, :message_action, :source_token, :license, :occurred_at, :timestamp

  attribute :timestamp, &:updated_at
end
