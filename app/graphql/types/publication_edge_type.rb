# frozen_string_literal: true

module Types
  class PublicationEdgeType < GraphQL::Types::Relay::BaseEdge
    node_type(Types::PublicationType)
  end
end
