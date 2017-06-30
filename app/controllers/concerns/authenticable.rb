# module Authenticable
#   extend ActiveSupport::Concern
#
#   included do
#
#     # looking for header "Authorization: Token token=12345"
#     def authenticate_user_from_token!
#       authenticate_with_http_token do |token, options|
#         return false unless token.present?
#
#         # create user from token
#         current_user = Datacentre.new(token)
#       end
#     end
#
#
#   end
# end
