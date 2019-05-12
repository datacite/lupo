# frozen_string_literal: true

class EventEdge < GraphQL::Relay::Edge
  def event
    logger = Logger.new(STDOUT)

    @event ||= begin
      Event.query(nil, subj_id: self.node[:id], obj_id: self.parent[:id])[:data].first
    end
  end

  def source
    event[:source_id].underscore.camelcase(:lower)
  end

  def relation_type
    event[:relation_type_id].underscore.camelcase(:lower)
  end

  def total
    event[:total]
  end
end
