# class DoiConnectionWithYearMonthType < GraphQL::Types::Relay::BaseConnection
#   edge_type(::DoiItemEdgeType)
  
#   field :views, [::Types::YearMonthType], null: true
#   field :downloads, [::Types::YearMonthType], null: true

#   def views
#     # - `object` is the Connection
#     # - `object.nodes` is the collection of Posts
#     #object.nodes.size
#   end

#   def downloads
#     # - `object` is the Connection
#     # - `object.nodes` is the collection of Posts
#     #object.nodes.size
#   end
# end