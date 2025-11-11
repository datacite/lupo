# frozen_string_literal: true

require "rails_helper"

describe MeType do
  describe "fields" do
    subject { described_class }

    it { is_expected.to have_field(:id).of_type("ID!") }
    it { is_expected.to have_field(:type).of_type("String!") }
    it { is_expected.to have_field(:name).of_type("String!") }
  end

  describe "find current_user" do
    let(:query) do
      "query {
        me {
          id
          name
        }
      }"
    end

    it "returns current_user" do
      # current_user is normally set in the API using the authorization header
      current_user =
        OpenStruct.new(uid: "0000-0001-5489-3594", name: "Josiah Carberry")
      response =
        LupoSchema.execute(query, context: { current_user: current_user }).
          as_json

      expect(response.dig("data", "me", "id")).to eq("0000-0001-5489-3594")
      expect(response.dig("data", "me", "name")).to eq("Josiah Carberry")
    end
  end

  describe "find current_user not authenticated" do
    let(:query) do
      "query {
        me {
          id
          name
        }
      }"
    end

    it "not returns current_user" do
      response = LupoSchema.execute(query).as_json

      expect(response.dig("data", "me", "id")).to be_nil
      expect(response.dig("data", "me", "name")).to be_nil
    end
  end
end
