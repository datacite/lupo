# frozen_string_literal: true

class EventDataEdge < GraphQL::Relay::Edge
  def event_data
    @event_data ||= begin
      Event.query(nil, subj_id: self.node[:id], obj_id: self.parent[:id])[:data].first
    end
  end

  def source
    event_data[:source_id].underscore.camelcase(:lower)
  end

  def relation_type
    event_data[:relation_type_id].underscore.camelcase(:lower)
  end

  def total
    event_data[:total]
  end
end
