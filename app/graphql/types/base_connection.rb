# frozen_string_literal: true

class BaseConnection < GraphQL::Types::Relay::BaseConnection
  include Facetable
  include Modelable
end
