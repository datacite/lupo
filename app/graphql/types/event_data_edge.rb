# frozen_string_literal: true

module Types
  class EventDataEdge < GraphQL::Relay::Edge
    RELATION_TYPES = {
      "funds" => "isFundedBy",
      "isFundedBy" => "funds",
      "authors" => "isAuthoredBy",
      "isAuthoredBy" => "authors"
    }

    def event_data
      @event_data ||= begin
        return nil unless self.node.present?
        Event.query(nil, subj_id: doi_from_node(self.node), obj_id: self.parent.id).results.first.to_h.fetch("_source", nil)
      end
    end

    def source_id
      self.node.identifier if self.node.present?
    end

    def target_id
      self.parent.id
    end

    def source
      event_data.source_id if event_data.present?
    end

    def relation_type
      event_data.relation_type_id.underscore.camelcase(:lower) if event_data.present?
    end

    def total
      event_data.total if event_data.present?
    end

    def doi_from_node(node)
      return nil unless node.present?

      "https://doi.org/#{node.uid.downcase}"
    end
  end
end
