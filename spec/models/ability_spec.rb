require 'rails_helper'
require "cancan/matchers"

describe User, type: :model do
  let(:token) { User.generate_token }
  let(:user) { User.new(token) }
  let(:provider) { create(:provider) }
  let(:client) { create(:client, provider: provider) }
  let(:doi) { create(:doi, client: client) }
  let(:prefix) { create(:prefix) }
  let(:client_prefix) { create(:client_prefix, client: client) }
  let(:provider_prefix) { create(:provider_prefix, provider: provider) }

  describe 'User attributes', :order => :defined do
    it "is valid with valid attributes" do
      expect(user.name).to eq("Josiah Carberry")
    end
  end

  describe "abilities" do
    subject { Ability.new(user) }

    context "when is a user" do
      let(:token){ User.generate_token(role_id: "user") }

      it{ is_expected.to be_able_to(:read, user) }

      it{ is_expected.not_to be_able_to(:read, provider) }
      it{ is_expected.not_to be_able_to(:create, provider) }
      it{ is_expected.not_to be_able_to(:update, provider) }
      it{ is_expected.not_to be_able_to(:destroy, provider) }

      it{ is_expected.not_to be_able_to(:read, client) }
      it{ is_expected.not_to be_able_to(:create, client) }
      it{ is_expected.not_to be_able_to(:update, client) }
      it{ is_expected.not_to be_able_to(:destroy, client) }

      it{ is_expected.not_to be_able_to(:read, prefix) }
      it{ is_expected.not_to be_able_to(:create, prefix) }
      it{ is_expected.not_to be_able_to(:update, prefix) }
      it{ is_expected.not_to be_able_to(:destroy, prefix) }
    end

    context "when is a client admin" do
      let(:token){ User.generate_token(role_id: "client_admin", provider_id: provider.symbol.downcase, client_id: client.symbol.downcase) }

      it{ is_expected.to be_able_to(:read, user) }

      it{ is_expected.not_to be_able_to(:read, provider) }
      it{ is_expected.not_to be_able_to(:create, provider) }
      it{ is_expected.not_to be_able_to(:update, provider) }
      it{ is_expected.not_to be_able_to(:destroy, provider) }

      it{ is_expected.to be_able_to(:read, client) }
      it{ is_expected.not_to be_able_to(:create, client) }
      it{ is_expected.to be_able_to(:update, client) }
      it{ is_expected.not_to be_able_to(:destroy, client) }

      it{ is_expected.not_to be_able_to(:read, prefix) }
      it{ is_expected.not_to be_able_to(:create, prefix) }
      it{ is_expected.not_to be_able_to(:update, prefix) }
      it{ is_expected.not_to be_able_to(:destroy, prefix) }

      it{ is_expected.to be_able_to(:read, client_prefix) }
      it{ is_expected.not_to be_able_to(:create, client_prefix) }
      it{ is_expected.not_to be_able_to(:update, client_prefix) }
      it{ is_expected.not_to be_able_to(:destroy, client_prefix) }
    end

    context "when is a client user" do
      let(:token){ User.generate_token(role_id: "client_user", provider_id: provider.symbol.downcase, client_id: client.symbol.downcase) }

      it{ is_expected.to be_able_to(:read, user) }

      it{ is_expected.not_to be_able_to(:read, provider) }
      it{ is_expected.not_to be_able_to(:create, provider) }
      it{ is_expected.not_to be_able_to(:update, provider) }
      it{ is_expected.not_to be_able_to(:destroy, provider) }

      it{ is_expected.to be_able_to(:read, client) }
      it{ is_expected.not_to be_able_to(:create, client) }
      it{ is_expected.not_to be_able_to(:update, client) }
      it{ is_expected.not_to be_able_to(:destroy, client) }

      it{ is_expected.not_to be_able_to(:read, prefix) }
      it{ is_expected.not_to be_able_to(:create, prefix) }
      it{ is_expected.not_to be_able_to(:update, prefix) }
      it{ is_expected.not_to be_able_to(:destroy, prefix) }

      it{ is_expected.to be_able_to(:read, client_prefix) }
      it{ is_expected.not_to be_able_to(:create, client_prefix) }
      it{ is_expected.not_to be_able_to(:update, client_prefix) }
      it{ is_expected.not_to be_able_to(:destroy, client_prefix) }
    end

    context "when is a provider admin" do
      let(:token){ User.generate_token(role_id: "provider_admin", provider_id: provider.symbol.downcase) }

      it{ is_expected.to be_able_to(:read, user) }

      it{ is_expected.to be_able_to(:read, provider) }
      it{ is_expected.not_to be_able_to(:create, provider) }
      it{ is_expected.to be_able_to(:update, provider) }
      it{ is_expected.not_to be_able_to(:destroy, provider) }

      it{ is_expected.to be_able_to(:read, client) }
      it{ is_expected.to be_able_to(:create, client) }
      it{ is_expected.to be_able_to(:update, client) }
      it{ is_expected.to be_able_to(:destroy, client) }

      it{ is_expected.not_to be_able_to(:read, prefix) }
      it{ is_expected.not_to be_able_to(:create, prefix) }
      it{ is_expected.not_to be_able_to(:update, prefix) }
      it{ is_expected.not_to be_able_to(:destroy, prefix) }

      it{ is_expected.to be_able_to(:read, provider_prefix) }
      it{ is_expected.to be_able_to(:create, provider_prefix) }
      it{ is_expected.to be_able_to(:update, provider_prefix) }
      it{ is_expected.to be_able_to(:destroy, provider_prefix) }
    end

    context "when is a provider user" do
      let(:token){ User.generate_token(role_id: "provider_user", provider_id: provider.symbol.downcase) }

      it{ is_expected.to be_able_to(:read, user) }

      it{ is_expected.to be_able_to(:read, provider) }
      it{ is_expected.not_to be_able_to(:create, provider) }
      it{ is_expected.not_to be_able_to(:update, provider) }
      it{ is_expected.not_to be_able_to(:destroy, provider) }

      it{ is_expected.to be_able_to(:read, client) }
      it{ is_expected.not_to be_able_to(:create, client) }
      it{ is_expected.not_to be_able_to(:update, client) }
      it{ is_expected.not_to be_able_to(:destroy, client) }

      it{ is_expected.not_to be_able_to(:read, prefix) }
      it{ is_expected.not_to be_able_to(:create, prefix) }
      it{ is_expected.not_to be_able_to(:update, prefix) }
      it{ is_expected.not_to be_able_to(:destroy, prefix) }

      it{ is_expected.to be_able_to(:read, provider_prefix) }
      it{ is_expected.not_to be_able_to(:create, provider_prefix) }
      it{ is_expected.not_to be_able_to(:update, provider_prefix) }
      it{ is_expected.not_to be_able_to(:destroy, provider_prefix) }
    end

    context "when is a staff admin" do
      it{ is_expected.to be_able_to(:read, user) }

      it{ is_expected.to be_able_to(:read, provider) }
      it{ is_expected.to be_able_to(:create, provider) }
      it{ is_expected.to be_able_to(:update, provider) }
      it{ is_expected.to be_able_to(:destroy, provider) }

      it{ is_expected.to be_able_to(:read, client) }
      it{ is_expected.to be_able_to(:create, client) }
      it{ is_expected.to be_able_to(:update, client) }
      it{ is_expected.to be_able_to(:destroy, client) }

      it{ is_expected.to be_able_to(:read, doi) }
    end

    context "when is a staff user" do
      let(:token){ User.generate_token(role_id: "staff_user") }

      it{ is_expected.to be_able_to(:read, user) }

      it{ is_expected.to be_able_to(:read, provider) }
      it{ is_expected.not_to be_able_to(:create, provider) }
      it{ is_expected.not_to be_able_to(:update, provider) }
      it{ is_expected.not_to be_able_to(:destroy, provider) }

      it{ is_expected.to be_able_to(:read, client) }
      it{ is_expected.not_to be_able_to(:create, client) }
      it{ is_expected.not_to be_able_to(:update, client) }
      it{ is_expected.not_to be_able_to(:destroy, client) }

      it{ is_expected.to be_able_to(:read, doi) }
    end

    context "when is anonymous" do
      let(:token) { nil }

      it{ is_expected.not_to be_able_to(:read, provider) }
      it{ is_expected.not_to be_able_to(:update, provider) }
      it{ is_expected.not_to be_able_to(:destroy, provider) }

      it{ is_expected.not_to be_able_to(:read, client) }
      it{ is_expected.not_to be_able_to(:create, client) }
      it{ is_expected.not_to be_able_to(:update, client) }
      it{ is_expected.not_to be_able_to(:destroy, client) }

      it{ is_expected.not_to be_able_to(:read, doi) }

      it{ is_expected.not_to be_able_to(:read, prefix) }
      it{ is_expected.not_to be_able_to(:create, prefix) }
      it{ is_expected.not_to be_able_to(:update, prefix) }
      it{ is_expected.not_to be_able_to(:destroy, prefix) }
    end
  end
end
