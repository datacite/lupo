# frozen_string_literal: true

class PublicationEdgeType < GraphQL::Types::Relay::BaseEdge
  node_type(PublicationType)
end
