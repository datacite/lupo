# frozen_string_literal: true

class EventDataEdge < GraphQL::Relay::Edge
  RELATION_TYPES = {
    "funds" => "isFundedBy",
    "isFundedBy" => "funds",
    "authors" => "isAuthoredBy",
    "isAuthoredBy" => "authors"
  }

  def event_data
    @event_data ||= begin
      Event.query(nil, subj_id: self.node[:id], obj_id: self.parent[:id])[:data].first
    end
  end

  def source
    event_data[:source_id].underscore.camelcase(:lower)
  end

  # We are switching subj and obj, and thus need to change direction of relation type
  def relation_type
    rt = event_data[:relation_type_id].underscore.camelcase(:lower)
    RELATION_TYPES.fetch(rt, rt) 
  end

  def total
    event_data[:total]
  end
end
