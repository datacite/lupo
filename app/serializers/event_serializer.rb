class EventSerializer < ActiveModel::Serializer
  cache key: 'event'
  attributes :subj_id, :obj_id, :message_action, :source_token, :relation_type_id, :source_id, :total, :license, :occurred_at, :timestamp, :subj, :obj

  def id
    object.to_param
  end

  def state
    object.aasm_state
  end

  def occured_at
    object.occured_at.utc.iso8601
  end
end
