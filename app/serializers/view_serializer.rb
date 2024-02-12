# frozen_string_literal: true

class ViewSerializer
  include FastJsonapi::ObjectSerializer

  set_key_transform :camel_lower
  set_type :events
  set_id :uuid

  attributes :subj_id,
             :obj_id,
             :source_id,
             :relation_type_id,
             :total,
             :message_action,
             :source_token,
             :license,
             :occurred_at,
             :timestamp

  # has_many :dois, record_type: :dois, serializer: DoiSerializer, id_method_name: :doi do |object|
  #   load_doi(object)
  # end

  attribute :timestamp, &:updated_at
end
