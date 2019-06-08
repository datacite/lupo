class V1::EventSerializer
  include FastJsonapi::ObjectSerializer
  set_key_transform :dash
  set_type :events
  set_id :uuid
  
  attributes :subj_id, :obj_id, :source_id, :relation_type_id, :total, :message_action, :source_token, :license, :occurred_at, :timestamp
  
  belongs_to :subj, serializer: V1::ObjectSerializer, record_type: :objects
  belongs_to :obj, serializer: V1::ObjectSerializer, record_type: :objects

  attribute :timestamp, &:updated_at
end
