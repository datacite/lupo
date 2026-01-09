# frozen_string_literal: true

class EventDataEdge < GraphQL::Types::Relay::BaseEdge
  node_type(EventDataType) # if you have a custom node type

  field :event_data, EventDataType, null: true
  field :source_id, String, null: true
  field :target_id, String, null: true
  field :source, String, null: true
  field :relation_type, String, null: true
  field :total, Integer, null: true

  RELATION_TYPES = {
    "funds" => "isFundedBy",
    "isFundedBy" => "funds",
    "authors" => "isAuthoredBy",
    "isAuthoredBy" => "authors",
  }.freeze

  def event_data
    @event_data ||=
      begin
        return nil if node.blank?

        Event.query(nil, subj_id: doi_from_node(node), obj_id: parent.id).
          results.
          first.
          to_h.
          fetch("_source", nil)
      end
  end

  def source_id
    node.identifier if node.present?
  end

  def target_id
    parent.id
  end

  def source
    event_data.source_id if event_data.present?
  end

  def relation_type
    if event_data.present?
      event_data.relation_type_id.underscore.camelcase(:lower)
    end
  end

  def total
    event_data.total if event_data.present?
  end

  def doi_from_node(node)
    return nil if node.blank?

    "https://doi.org/#{node.uid.downcase}"
  end
end
