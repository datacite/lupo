class LupoSchema < GraphQL::Schema
  default_max_page_size 1000

  # mutation(Types::MutationType)
  query(Types::QueryType)
end
