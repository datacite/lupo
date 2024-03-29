# frozen_string_literal: true

require "rails_helper"
require "cancan/matchers"

describe User, type: :model, elasticsearch: true do
  let(:token) { User.generate_token }
  let(:user) { User.new(token) }
  let!(:consortium) { create(:provider, role_name: "ROLE_CONSORTIUM") }
  let!(:provider) do
    create(
      :provider,
      consortium: consortium, role_name: "ROLE_CONSORTIUM_ORGANIZATION",
    )
  end
  let(:contact) { create(:contact, provider: provider) }
  let(:consortium_contact) { create(:contact, provider: consortium) }
  let!(:prefix) { create(:prefix, uid: "10.14454") }
  let!(:client) { create(:client, provider: provider) }
  let!(:provider_prefix) do
    create(:provider_prefix, provider: provider, prefix: prefix)
  end
  let!(:client_prefix) do
    create(:client_prefix, client: client, prefix: prefix)
  end
  let(:doi) { create(:doi, client: client) }
  let(:media) { create(:media, doi: doi) }
  let(:xml) { file_fixture("datacite.xml").read }
  let(:metadata) { create(:metadata, xml: xml, doi: doi) }

  describe "User attributes", order: :defined do
    it "is valid with valid attributes" do
      expect(user.name).to eq("Josiah Carberry")
    end
  end

  describe "abilities", vcr: true do
    subject { Ability.new(user) }

    context "when is a user" do
      let(:token) { User.generate_token(role_id: "user") }

      it { is_expected.to be_able_to(:read, user) }
      it { is_expected.to be_able_to(:read, provider) }

      it { is_expected.not_to be_able_to(:create, provider) }
      it { is_expected.not_to be_able_to(:update, provider) }
      it { is_expected.not_to be_able_to(:destroy, provider) }
      it { is_expected.not_to be_able_to(:read_billing_information, provider) }
      it { is_expected.not_to be_able_to(:read_contact_information, provider) }

      it { is_expected.not_to be_able_to(:read, contact) }
      it { is_expected.not_to be_able_to(:create, contact) }
      it { is_expected.not_to be_able_to(:update, contact) }
      it { is_expected.not_to be_able_to(:destroy, contact) }

      it { is_expected.not_to be_able_to(:read, client) }
      it { is_expected.not_to be_able_to(:create, client) }
      it { is_expected.not_to be_able_to(:update, client) }
      it { is_expected.not_to be_able_to(:destroy, client) }
      it { is_expected.not_to be_able_to(:transfer, client) }
      it { is_expected.not_to be_able_to(:read_contact_information, client) }
      it { is_expected.not_to be_able_to(:read_analytics, client) }

      it { is_expected.not_to be_able_to(:read, prefix) }
      it { is_expected.not_to be_able_to(:create, prefix) }
      it { is_expected.not_to be_able_to(:update, prefix) }
      it { is_expected.not_to be_able_to(:destroy, prefix) }

      it { is_expected.to be_able_to(:read, doi) }
      it { is_expected.not_to be_able_to(:transfer, doi) }
      it { is_expected.not_to be_able_to(:create, doi) }
      it { is_expected.not_to be_able_to(:update, doi) }
      it { is_expected.not_to be_able_to(:destroy, doi) }
    end

    context "when is a client admin" do
      let(:token) do
        User.generate_token(
          role_id: "client_admin",
          provider_id: provider.symbol.downcase,
          client_id: client.symbol.downcase,
        )
      end

      it { is_expected.to be_able_to(:read, user) }
      it { is_expected.to be_able_to(:read, provider) }

      it { is_expected.not_to be_able_to(:create, provider) }
      it { is_expected.not_to be_able_to(:update, provider) }
      it { is_expected.not_to be_able_to(:destroy, provider) }
      it { is_expected.not_to be_able_to(:read_billing_information, provider) }
      it { is_expected.not_to be_able_to(:read_contact_information, provider) }

      it { is_expected.not_to be_able_to(:read, contact) }
      it { is_expected.not_to be_able_to(:create, contact) }
      it { is_expected.not_to be_able_to(:update, contact) }
      it { is_expected.not_to be_able_to(:destroy, contact) }

      it { is_expected.to be_able_to(:read, client) }
      it { is_expected.not_to be_able_to(:create, client) }
      it { is_expected.to be_able_to(:update, client) }
      it { is_expected.not_to be_able_to(:destroy, client) }
      it { is_expected.not_to be_able_to(:transfer, client) }
      it { is_expected.to be_able_to(:read_contact_information, client) }
      it { is_expected.to be_able_to(:read_analytics, client) }

      it { is_expected.not_to be_able_to(:read, prefix) }
      it { is_expected.not_to be_able_to(:create, prefix) }
      it { is_expected.not_to be_able_to(:update, prefix) }
      it { is_expected.not_to be_able_to(:destroy, prefix) }

      it { is_expected.to be_able_to(:read, client_prefix) }
      it { is_expected.not_to be_able_to(:create, client_prefix) }
      it { is_expected.not_to be_able_to(:update, client_prefix) }
      it { is_expected.not_to be_able_to(:destroy, client_prefix) }

      it { is_expected.to be_able_to(:read, doi) }
      it { is_expected.not_to be_able_to(:transfer, doi) }
      it { is_expected.to be_able_to(:create, doi) }
      it { is_expected.to be_able_to(:update, doi) }
      it { is_expected.to be_able_to(:destroy, doi) }
    end

    context "when is a client admin inactive" do
      let(:client) { create(:client, provider: provider, is_active: false) }
      let(:token) do
        User.generate_token(
          role_id: "client_admin",
          provider_id: provider.symbol.downcase,
          client_id: client.symbol.downcase,
        )
      end

      it { is_expected.to be_able_to(:read, user) }
      it { is_expected.to be_able_to(:read, provider) }

      it { is_expected.not_to be_able_to(:create, provider) }
      it { is_expected.not_to be_able_to(:update, provider) }
      it { is_expected.not_to be_able_to(:destroy, provider) }
      it { is_expected.not_to be_able_to(:read_billing_information, provider) }
      it { is_expected.not_to be_able_to(:read_contact_information, provider) }

      it { is_expected.not_to be_able_to(:read, contact) }
      it { is_expected.not_to be_able_to(:create, contact) }
      it { is_expected.not_to be_able_to(:update, contact) }
      it { is_expected.not_to be_able_to(:destroy, contact) }

      it { is_expected.to be_able_to(:read, client) }
      it { is_expected.not_to be_able_to(:create, client) }
      it { is_expected.not_to be_able_to(:update, client) }
      it { is_expected.not_to be_able_to(:destroy, client) }
      it { is_expected.not_to be_able_to(:transfer, client) }
      it { is_expected.to be_able_to(:read_contact_information, client) }
      it { is_expected.to be_able_to(:read_analytics, client) }

      it { is_expected.not_to be_able_to(:read, prefix) }
      it { is_expected.not_to be_able_to(:create, prefix) }
      it { is_expected.not_to be_able_to(:update, prefix) }
      it { is_expected.not_to be_able_to(:destroy, prefix) }

      it { is_expected.to be_able_to(:read, client_prefix) }
      it { is_expected.not_to be_able_to(:create, client_prefix) }
      it { is_expected.not_to be_able_to(:update, client_prefix) }
      it { is_expected.not_to be_able_to(:destroy, client_prefix) }

      it { is_expected.to be_able_to(:read, doi) }
      it { is_expected.not_to be_able_to(:transfer, doi) }
      it { is_expected.not_to be_able_to(:create, doi) }
      it { is_expected.not_to be_able_to(:update, doi) }
      it { is_expected.not_to be_able_to(:destroy, doi) }
    end

    context "when is a client user" do
      let(:token) do
        User.generate_token(
          role_id: "client_user",
          provider_id: provider.symbol.downcase,
          client_id: client.symbol.downcase,
        )
      end

      it { is_expected.to be_able_to(:read, user) }
      it { is_expected.to be_able_to(:read, provider) }

      it { is_expected.not_to be_able_to(:create, provider) }
      it { is_expected.not_to be_able_to(:update, provider) }
      it { is_expected.not_to be_able_to(:destroy, provider) }
      it { is_expected.not_to be_able_to(:read_billing_information, provider) }
      it { is_expected.not_to be_able_to(:read_contact_information, provider) }

      it { is_expected.not_to be_able_to(:read, contact) }
      it { is_expected.not_to be_able_to(:create, contact) }
      it { is_expected.not_to be_able_to(:update, contact) }
      it { is_expected.not_to be_able_to(:destroy, contact) }

      it { is_expected.to be_able_to(:read, client) }
      it { is_expected.not_to be_able_to(:create, client) }
      it { is_expected.not_to be_able_to(:update, client) }
      it { is_expected.not_to be_able_to(:destroy, client) }
      it { is_expected.not_to be_able_to(:transfer, client) }
      it { is_expected.to be_able_to(:read_contact_information, client) }
      it { is_expected.to be_able_to(:read_analytics, client) }

      it { is_expected.not_to be_able_to(:read, prefix) }
      it { is_expected.not_to be_able_to(:create, prefix) }
      it { is_expected.not_to be_able_to(:update, prefix) }
      it { is_expected.not_to be_able_to(:destroy, prefix) }

      it { is_expected.to be_able_to(:read, client_prefix) }
      it { is_expected.not_to be_able_to(:create, client_prefix) }
      it { is_expected.not_to be_able_to(:update, client_prefix) }
      it { is_expected.not_to be_able_to(:destroy, client_prefix) }

      it { is_expected.to be_able_to(:read, doi) }
      it { is_expected.not_to be_able_to(:transfer, doi) }
      it { is_expected.not_to be_able_to(:create, doi) }
      it { is_expected.not_to be_able_to(:update, doi) }
      it { is_expected.not_to be_able_to(:destroy, doi) }
    end

    context "when is a provider admin" do
      let(:token) do
        User.generate_token(
          role_id: "provider_admin", provider_id: provider.symbol.downcase,
        )
      end

      it { is_expected.to be_able_to(:read, user) }

      it { is_expected.to be_able_to(:read, provider) }
      it { is_expected.not_to be_able_to(:create, provider) }
      it { is_expected.to be_able_to(:update, provider) }
      it { is_expected.not_to be_able_to(:destroy, provider) }
      it { is_expected.to be_able_to(:read_billing_information, provider) }
      it { is_expected.to be_able_to(:read_contact_information, provider) }

      it { is_expected.to be_able_to(:read, contact) }
      it { is_expected.to be_able_to(:create, contact) }
      it { is_expected.to be_able_to(:update, contact) }
      it { is_expected.to be_able_to(:destroy, contact) }

      it { is_expected.to be_able_to(:read, client) }
      it { is_expected.to be_able_to(:create, client) }
      it { is_expected.to be_able_to(:update, client) }
      it { is_expected.to be_able_to(:destroy, client) }
      it { is_expected.not_to be_able_to(:transfer, client) }
      it { is_expected.to be_able_to(:read_contact_information, client) }
      it { is_expected.to be_able_to(:read_analytics, client) }

      it { is_expected.not_to be_able_to(:read, prefix) }
      it { is_expected.not_to be_able_to(:create, prefix) }
      it { is_expected.not_to be_able_to(:update, prefix) }
      it { is_expected.not_to be_able_to(:destroy, prefix) }

      it { is_expected.to be_able_to(:read, provider_prefix) }
      it { is_expected.to be_able_to(:create, provider_prefix) }
      it { is_expected.to be_able_to(:update, provider_prefix) }
      it { is_expected.to be_able_to(:destroy, provider_prefix) }

      it { is_expected.to be_able_to(:read, doi) }
      it { is_expected.to be_able_to(:transfer, doi) }
      it { is_expected.not_to be_able_to(:create, doi) }
      it { is_expected.not_to be_able_to(:update, doi) }
      it { is_expected.not_to be_able_to(:destroy, doi) }
    end

    context "when is a consortium admin" do
      let(:token) do
        User.generate_token(
          role_id: "consortium_admin", provider_id: consortium.symbol.downcase,
        )
      end

      it { is_expected.to be_able_to(:read, user) }

      it { is_expected.to be_able_to(:read, consortium) }
      it { is_expected.not_to be_able_to(:create, consortium) }
      it { is_expected.to be_able_to(:update, consortium) }
      it { is_expected.not_to be_able_to(:destroy, consortium) }
      it { is_expected.to be_able_to(:read_billing_information, provider) }
      it { is_expected.to be_able_to(:read_contact_information, provider) }

      it { is_expected.to be_able_to(:read, contact) }
      it { is_expected.to be_able_to(:create, contact) }
      it { is_expected.to be_able_to(:update, contact) }
      it { is_expected.to be_able_to(:destroy, contact) }

      it { is_expected.to be_able_to(:read, consortium_contact) }
      it { is_expected.to be_able_to(:create, consortium_contact) }
      it { is_expected.to be_able_to(:update, consortium_contact) }
      it { is_expected.to be_able_to(:destroy, consortium_contact) }

      it { is_expected.to be_able_to(:read, provider) }
      it { is_expected.to be_able_to(:create, provider) }
      it { is_expected.to be_able_to(:update, provider) }
      it { is_expected.to be_able_to(:destroy, provider) }
      it { is_expected.to be_able_to(:transfer, client) }

      it { is_expected.to be_able_to(:read, client) }
      it { is_expected.to be_able_to(:create, client) }
      it { is_expected.to be_able_to(:update, client) }
      it { is_expected.to be_able_to(:destroy, client) }
      it { is_expected.to be_able_to(:read_contact_information, client) }
      it { is_expected.to be_able_to(:read_analytics, client) }

      it { is_expected.not_to be_able_to(:read, prefix) }
      it { is_expected.not_to be_able_to(:create, prefix) }
      it { is_expected.not_to be_able_to(:update, prefix) }
      it { is_expected.not_to be_able_to(:destroy, prefix) }

      it { is_expected.to be_able_to(:read, provider_prefix) }
      it { is_expected.to be_able_to(:create, provider_prefix) }
      it { is_expected.to be_able_to(:update, provider_prefix) }
      it { is_expected.to be_able_to(:destroy, provider_prefix) }

      it { is_expected.to be_able_to(:read, doi) }
      it { is_expected.to be_able_to(:transfer, doi) }
      it { is_expected.not_to be_able_to(:create, doi) }
      it { is_expected.not_to be_able_to(:update, doi) }
      it { is_expected.not_to be_able_to(:destroy, doi) }
    end

    context "when is a provider user" do
      let(:token) do
        User.generate_token(
          role_id: "provider_user", provider_id: provider.symbol.downcase,
        )
      end

      it { is_expected.to be_able_to(:read, user) }

      it { is_expected.to be_able_to(:read, provider) }
      it { is_expected.not_to be_able_to(:create, provider) }
      it { is_expected.not_to be_able_to(:update, provider) }
      it { is_expected.not_to be_able_to(:destroy, provider) }
      it { is_expected.to be_able_to(:read_billing_information, provider) }
      it { is_expected.to be_able_to(:read_contact_information, provider) }

      it { is_expected.to be_able_to(:read, contact) }
      it { is_expected.not_to be_able_to(:create, contact) }
      it { is_expected.not_to be_able_to(:update, contact) }
      it { is_expected.not_to be_able_to(:destroy, contact) }

      it { is_expected.to be_able_to(:read, client) }
      it { is_expected.not_to be_able_to(:create, client) }
      it { is_expected.not_to be_able_to(:update, client) }
      it { is_expected.not_to be_able_to(:destroy, client) }
      it { is_expected.not_to be_able_to(:transfer, client) }
      it { is_expected.to be_able_to(:read_contact_information, client) }
      it { is_expected.to be_able_to(:read_analytics, client) }

      it { is_expected.not_to be_able_to(:read, prefix) }
      it { is_expected.not_to be_able_to(:create, prefix) }
      it { is_expected.not_to be_able_to(:update, prefix) }
      it { is_expected.not_to be_able_to(:destroy, prefix) }

      it { is_expected.to be_able_to(:read, provider_prefix) }
      it { is_expected.not_to be_able_to(:create, provider_prefix) }
      it { is_expected.not_to be_able_to(:update, provider_prefix) }
      it { is_expected.not_to be_able_to(:destroy, provider_prefix) }

      it { is_expected.to be_able_to(:read, doi) }
      it { is_expected.not_to be_able_to(:transfer, doi) }
      it { is_expected.not_to be_able_to(:create, doi) }
      it { is_expected.not_to be_able_to(:update, doi) }
      it { is_expected.not_to be_able_to(:destroy, doi) }
    end

    context "when is a staff admin" do
      it { is_expected.to be_able_to(:read, user) }

      it { is_expected.to be_able_to(:read, provider) }
      it { is_expected.to be_able_to(:create, provider) }
      it { is_expected.to be_able_to(:update, provider) }
      it { is_expected.to be_able_to(:destroy, provider) }
      it { is_expected.to be_able_to(:transfer, client) }
      it { is_expected.to be_able_to(:read_billing_information, provider) }
      it { is_expected.to be_able_to(:read_contact_information, provider) }

      it { is_expected.to be_able_to(:read, contact) }
      it { is_expected.to be_able_to(:create, contact) }
      it { is_expected.to be_able_to(:update, contact) }
      it { is_expected.to be_able_to(:destroy, contact) }

      it { is_expected.to be_able_to(:read, client) }
      it { is_expected.to be_able_to(:create, client) }
      it { is_expected.to be_able_to(:update, client) }
      it { is_expected.to be_able_to(:destroy, client) }
      it { is_expected.to be_able_to(:read_contact_information, client) }
      it { is_expected.to be_able_to(:read_analytics, client) }

      it { is_expected.to be_able_to(:read, doi) }
      it { is_expected.to be_able_to(:transfer, doi) }
      it { is_expected.to be_able_to(:create, doi) }
      it { is_expected.to be_able_to(:update, doi) }
      it { is_expected.to be_able_to(:destroy, doi) }
    end

    context "when is a staff user" do
      let(:token) { User.generate_token(role_id: "staff_user") }

      it { is_expected.to be_able_to(:read, user) }

      it { is_expected.to be_able_to(:read, provider) }
      it { is_expected.not_to be_able_to(:create, provider) }
      it { is_expected.not_to be_able_to(:update, provider) }
      it { is_expected.not_to be_able_to(:destroy, provider) }
      it { is_expected.to be_able_to(:read_billing_information, provider) }
      it { is_expected.to be_able_to(:read_contact_information, provider) }

      it { is_expected.to be_able_to(:read, contact) }
      it { is_expected.not_to be_able_to(:create, contact) }
      it { is_expected.not_to be_able_to(:update, contact) }
      it { is_expected.not_to be_able_to(:destroy, contact) }

      it { is_expected.to be_able_to(:read, client) }
      it { is_expected.not_to be_able_to(:create, client) }
      it { is_expected.not_to be_able_to(:update, client) }
      it { is_expected.not_to be_able_to(:destroy, client) }
      it { is_expected.not_to be_able_to(:transfer, client) }
      it { is_expected.to be_able_to(:read_contact_information, client) }
      it { is_expected.to be_able_to(:read_analytics, client) }

      it { is_expected.to be_able_to(:read, doi) }
      it { is_expected.not_to be_able_to(:transfer, doi) }
      it { is_expected.not_to be_able_to(:create, doi) }
      it { is_expected.not_to be_able_to(:update, doi) }
      it { is_expected.not_to be_able_to(:destroy, doi) }
    end

    context "when is temporary" do
      let(:token) { User.generate_token(role_id: "temporary", provider_id: provider.symbol.downcase, client_id: client.symbol.downcase) }

      it { is_expected.to be_able_to(:read, user) }

      it { is_expected.to be_able_to(:read, provider) }
      it { is_expected.not_to be_able_to(:create, provider) }
      it { is_expected.to be_able_to(:update, provider) }
      it { is_expected.not_to be_able_to(:destroy, provider) }
      it { is_expected.not_to be_able_to(:read_billing_information, provider) }
      it { is_expected.to be_able_to(:read_contact_information, provider) }

      it { is_expected.not_to be_able_to(:read, contact) }
      it { is_expected.not_to be_able_to(:create, contact) }
      it { is_expected.not_to be_able_to(:update, contact) }
      it { is_expected.not_to be_able_to(:destroy, contact) }

      it { is_expected.to be_able_to(:read, client) }
      it { is_expected.not_to be_able_to(:create, client) }
      it { is_expected.to be_able_to(:update, client) }
      it { is_expected.not_to be_able_to(:destroy, client) }
      it { is_expected.not_to be_able_to(:transfer, client) }
      it { is_expected.to be_able_to(:read_contact_information, client) }

      it { is_expected.to be_able_to(:read, doi) }
      it { is_expected.not_to be_able_to(:transfer, doi) }
      it { is_expected.not_to be_able_to(:create, doi) }
      it { is_expected.not_to be_able_to(:update, doi) }
      it { is_expected.not_to be_able_to(:destroy, doi) }
    end

    context "when is anonymous" do
      let(:token) { nil }

      it { is_expected.not_to be_able_to(:create, provider) }
      it { is_expected.not_to be_able_to(:update, provider) }
      it { is_expected.not_to be_able_to(:destroy, provider) }
      it { is_expected.not_to be_able_to(:read_billing_information, provider) }
      it { is_expected.not_to be_able_to(:read_contact_information, provider) }

      it { is_expected.not_to be_able_to(:read, contact) }
      it { is_expected.not_to be_able_to(:create, contact) }
      it { is_expected.not_to be_able_to(:update, contact) }
      it { is_expected.not_to be_able_to(:destroy, contact) }

      it { is_expected.not_to be_able_to(:read, client) }
      it { is_expected.not_to be_able_to(:create, client) }
      it { is_expected.not_to be_able_to(:update, client) }
      it { is_expected.not_to be_able_to(:destroy, client) }
      it { is_expected.not_to be_able_to(:transfer, client) }
      it { is_expected.not_to be_able_to(:read_contact_information, client) }
      it { is_expected.not_to be_able_to(:read_analytics, client) }

      it { is_expected.to be_able_to(:read, doi) }
      it { is_expected.not_to be_able_to(:transfer, doi) }
      it { is_expected.not_to be_able_to(:create, doi) }
      it { is_expected.not_to be_able_to(:update, doi) }
      it { is_expected.not_to be_able_to(:destroy, doi) }

      it { is_expected.not_to be_able_to(:read, prefix) }
      it { is_expected.not_to be_able_to(:create, prefix) }
      it { is_expected.not_to be_able_to(:update, prefix) }
      it { is_expected.not_to be_able_to(:destroy, prefix) }
    end
  end
end
