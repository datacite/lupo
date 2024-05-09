# frozen_string_literal: true

require "rails_helper"

describe User, type: :model do
  describe "from token" do
    let(:token) { User.generate_token }
    let(:user) { User.new(token) }

    describe "User attributes" do
      it "has role_id" do
        expect(user.role_id).to eq("staff_admin")
      end

      it "has name" do
        expect(user.name).to eq("Josiah Carberry")
      end
    end
  end

  describe "reset client password", vcr: true do
    let(:provider) do
      create(:provider, symbol: "DATACITE", password_input: "12345")
    end
    let(:client) do
      create(
        :client,
        provider: provider,
        symbol: "DATACITE.DATACITE",
        system_email: "test@datacite.org",
      )
    end

    it "sends message" do
      response = User.reset(client.symbol)
      expect(response[:status]).to eq(200)
      expect(response[:message]).to eq("Queued. Thank you.")
    end
  end
end
