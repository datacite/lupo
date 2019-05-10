# frozen_string_literal: true

class LupoSchema < GraphQL::Schema
  default_max_page_size 100
  max_depth 5

  # mutation(Types::MutationType)
  query(Types::QueryType)
end
