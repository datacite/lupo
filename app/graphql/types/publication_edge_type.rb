# frozen_string_literal: true

class Types::PublicationEdgeType < GraphQL::Types::Relay::BaseEdge
  node_type(Types::PublicationType)
end
