
class EventSerializer
  include FastJsonapi::ObjectSerializer
  include BatchLoaderHelper

  set_key_transform :camel_lower
  set_type :events
  set_id :uuid
  
  attributes :subj_id, :obj_id, :source_id, :relation_type_id, :total, :message_action, :source_token, :license, :occurred_at, :timestamp
   
  has_many :dois, record_type: :dois, id_method_name: :doi

  attribute :timestamp, &:updated_at
end
