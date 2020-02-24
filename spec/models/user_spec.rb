require 'rails_helper'

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

  describe "from basic_auth admin" do
    let(:provider) { create(:provider, role_name: "ROLE_ADMIN", symbol: "ADMIN", password_input: "12345") }
    let(:credentials) { provider.encode_auth_param(username: provider.symbol, password: 12345) }
    let(:user) { User.new(credentials, type: "basic") }

    describe 'User attributes' do
      it "has role_id" do
        expect(user.role_id).to eq("staff_admin")
      end

      it "has no consortium_id" do
        expect(user.consortium_id).to be_nil
      end

      it "has no provider_id" do
        expect(user.provider_id).to be_nil
      end

      it "has name" do
        expect(user.name).to eq("My provider")
      end
    end
  end

  describe "from basic_auth provider" do
    let(:provider) { create(:provider, password_input: "12345") }
    let(:credentials) { provider.encode_auth_param(username: provider.symbol, password: 12345) }
    let(:user) { User.new(credentials, type: "basic") }

    describe 'User attributes' do
      it "has role_id" do
        expect(user.role_id).to eq("provider_admin")
      end

      it "has no consortium_id" do
        expect(user.consortium_id).to be_nil
      end

      it "has provider" do
        expect(user.provider_id).to eq(provider.symbol.downcase)
        expect(user.provider.name).to eq(provider.name)
      end

      it "has name" do
        expect(user.name).to eq("My provider")
      end
    end
  end

  describe "from basic_auth consortium" do
    let(:provider) { create(:provider, password_input: "12345", role_name: "ROLE_CONSORTIUM") }
    let(:credentials) { provider.encode_auth_param(username: provider.symbol, password: 12345) }
    let(:user) { User.new(credentials, type: "basic") }

    describe 'User attributes' do
      it "has role_id" do
        expect(user.role_id).to eq("provider_admin")
      end

      it "has consortium_id" do
        expect(user.consortium_id).to eq(provider.symbol.downcase)
      end

      it "has provider" do
        expect(user.provider_id).to eq(provider.symbol.downcase)
        expect(user.provider.name).to eq(provider.name)
      end

      it "has name" do
        expect(user.name).to eq("My provider")
      end
    end
  end

  describe "from basic_auth client" do
    let(:client) { create(:client, password_input: "12345") }
    let(:credentials) { client.encode_auth_param(username: client.symbol, password: 12345) }
    let(:user) { User.new(credentials, type: "basic") }

    describe 'User attributes' do
      it "has role_id" do
        expect(user.role_id).to eq("client_admin")
      end

      it "has no consortium_id" do
        expect(user.consortium_id).to be_nil
      end

      it "has provider_id" do
        expect(user.provider_id).to eq(client.symbol.downcase.split(".").first)
      end

      it "has client" do
        expect(user.client_id).to eq(client.symbol.downcase)
        expect(user.client.name).to eq(client.name)
      end

      it "has name" do
        expect(user.name).to eq("My data center")
      end
    end
  end

  describe "reset client password", vcr: true do
    let(:provider) { create(:provider, symbol: "DATACITE", password_input: "12345") }
    let(:client) { create(:client, provider: provider, symbol: "DATACITE.DATACITE", system_email: "test@datacite.org") }

    it "sends message" do
      response = User.reset(client.symbol)
      expect(response[:status]).to eq(200)
      expect(response[:message]).to eq("Queued. Thank you.")
    end
  end
end
