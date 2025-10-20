# frozen_string_literal: true

# require "rails_helper"

# describe MeType, type: :request do
#   describe "find current_user" do
#     let(:bearer) { User.generate_token(role_id: "user") }
#     let(:headers) { { 'HTTP_AUTHORIZATION' => 'Bearer ' + bearer }}
#     let(:query) do
#       %(query {
#         me {
#           id
#           name
#           betaTester
#         }
#       })
#     end

#     it "returns current_user" do
#       post '/client-api/graphql', { query: query }, headers
#       put last_response.body
#       expect(last_response.status).to eq(200)
#       expect(json.dig("data", "me", "id")).to eq("0000-0001-5489-3594")
#       expect(json.dig("data", "me", "name")).to eq("Josiah Carberry")
#       expect(json.dig("data", "me", "betaTester")).to be false
#     end
#   end

#   describe "find current_user not authenticated" do
#     let(:query) do
#       %(query {
#         me {
#           id
#           name
#           betaTester
#         }
#       })
#     end

#     it "not returns current_user" do
#       post '/client-api/graphql', { query: query }

#       expect(last_response.status).to eq(200)
#       expect(json.dig("data", "me", "id")).to be_nil
#       expect(json.dig("data", "me", "name")).to be_nil
#       expect(json.dig("data", "me", "betaTester")).to be_nil
#     end
#   end
# end
