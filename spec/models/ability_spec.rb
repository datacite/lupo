# frozen_string_literal: true

require "rails_helper"
require "cancan/matchers"

describe User, type: :model do
  let(:token) { User.generate_token }
  let(:user) { User.new(token) }
  let(:consortium) { create(:provider, role_name: "ROLE_CONSORTIUM") }
  let(:provider) do
    create(
      :provider,
      consortium: consortium, role_name: "ROLE_CONSORTIUM_ORGANIZATION",
    )
  end
  let(:contact) { create(:contact, provider: provider) }
  let(:consortium_contact) { create(:contact, provider: consortium) }
  let!(:prefix) { create(:prefix, uid: "10.14455") }
  let(:client) { create(:client, provider: provider) }
  let!(:client_prefix) do
    create(:client_prefix, client: client, prefix: prefix)
  end
  let(:provider_prefix) do
    create(:provider_prefix, provider: provider, prefix: prefix)
  end
  let(:doi) { create(:doi, client: client, doi: (prefix.uid + "/" + Faker::Internet.password(8)).downcase) }
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

      it "", :skip_prefix_pool do is_expected.to be_able_to(:read, user) end
      it "", :skip_prefix_pool do is_expected.to be_able_to(:read, provider) end

      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:create, provider) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:update, provider) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:destroy, provider) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:read_billing_information, provider) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:read_contact_information, provider) end

      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:read, contact) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:create, contact) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:update, contact) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:destroy, contact) end

      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:read, client) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:create, client) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:update, client) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:destroy, client) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:transfer, client) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:read_contact_information, client) end

      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:read, prefix) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:create, prefix) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:update, prefix) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:destroy, prefix) end

      it "", :skip_prefix_pool do is_expected.to be_able_to(:read, doi) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:transfer, doi) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:create, doi) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:update, doi) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:destroy, doi) end
    end

    context "when is a client admin" do
      let(:token) do
        User.generate_token(
          role_id: "client_admin",
          provider_id: provider.symbol.downcase,
          client_id: client.symbol.downcase,
        )
      end

      it "", :skip_prefix_pool do is_expected.to be_able_to(:read, user) end
      it "", :skip_prefix_pool do is_expected.to be_able_to(:read, provider) end

      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:create, provider) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:update, provider) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:destroy, provider) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:read_billing_information, provider) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:read_contact_information, provider) end

      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:read, contact) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:create, contact) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:update, contact) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:destroy, contact) end

      it "", :skip_prefix_pool do is_expected.to be_able_to(:read, client) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:create, client) end
      it "", :skip_prefix_pool do is_expected.to be_able_to(:update, client) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:destroy, client) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:transfer, client) end
      it "", :skip_prefix_pool do is_expected.to be_able_to(:read_contact_information, client) end

      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:read, prefix) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:create, prefix) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:update, prefix) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:destroy, prefix) end

      it "", :skip_prefix_pool do is_expected.to be_able_to(:read, client_prefix) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:create, client_prefix) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:update, client_prefix) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:destroy, client_prefix) end

      it "", :skip_prefix_pool do is_expected.to be_able_to(:read, doi) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:transfer, doi) end
      it "", :skip_prefix_pool do is_expected.to be_able_to(:create, doi) end
      it "", :skip_prefix_pool do is_expected.to be_able_to(:update, doi) end
      it "", :skip_prefix_pool do is_expected.to be_able_to(:destroy, doi) end
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

      it "", :skip_prefix_pool do is_expected.to be_able_to(:read, user) end
      it "", :skip_prefix_pool do is_expected.to be_able_to(:read, provider) end

      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:create, provider) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:update, provider) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:destroy, provider) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:read_billing_information, provider) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:read_contact_information, provider) end

      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:read, contact) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:create, contact) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:update, contact) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:destroy, contact) end

      it "", :skip_prefix_pool do is_expected.to be_able_to(:read, client) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:create, client) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:update, client) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:destroy, client) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:transfer, client) end
      it "", :skip_prefix_pool do is_expected.to be_able_to(:read_contact_information, client) end

      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:read, prefix) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:create, prefix) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:update, prefix) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:destroy, prefix) end

      it "", :skip_prefix_pool do is_expected.to be_able_to(:read, client_prefix) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:create, client_prefix) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:update, client_prefix) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:destroy, client_prefix) end

      it "", :skip_prefix_pool do is_expected.to be_able_to(:read, doi) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:transfer, doi) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:create, doi) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:update, doi) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:destroy, doi) end
    end

    context "when is a client user" do
      let(:token) do
        User.generate_token(
          role_id: "client_user",
          provider_id: provider.symbol.downcase,
          client_id: client.symbol.downcase,
        )
      end

      it "", :skip_prefix_pool do is_expected.to be_able_to(:read, user) end
      it "", :skip_prefix_pool do is_expected.to be_able_to(:read, provider) end

      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:create, provider) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:update, provider) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:destroy, provider) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:read_billing_information, provider) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:read_contact_information, provider) end

      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:read, contact) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:create, contact) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:update, contact) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:destroy, contact) end

      it "", :skip_prefix_pool do is_expected.to be_able_to(:read, client) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:create, client) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:update, client) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:destroy, client) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:transfer, client) end
      it "", :skip_prefix_pool do is_expected.to be_able_to(:read_contact_information, client) end

      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:read, prefix) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:create, prefix) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:update, prefix) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:destroy, prefix) end

      it "", :skip_prefix_pool do is_expected.to be_able_to(:read, client_prefix) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:create, client_prefix) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:update, client_prefix) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:destroy, client_prefix) end

      it "", :skip_prefix_pool do is_expected.to be_able_to(:read, doi) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:transfer, doi) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:create, doi) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:update, doi) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:destroy, doi) end
    end

    context "when is a provider admin" do
      let(:token) do
        User.generate_token(
          role_id: "provider_admin", provider_id: provider.symbol.downcase,
        )
      end

      it "", :skip_prefix_pool do is_expected.to be_able_to(:read, user) end

      it "", :skip_prefix_pool do is_expected.to be_able_to(:read, provider) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:create, provider) end
      it "", :skip_prefix_pool do is_expected.to be_able_to(:update, provider) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:destroy, provider) end
      it "", :skip_prefix_pool do is_expected.to be_able_to(:read_billing_information, provider) end
      it "", :skip_prefix_pool do is_expected.to be_able_to(:read_contact_information, provider) end

      it "", :skip_prefix_pool do is_expected.to be_able_to(:read, contact) end
      it "", :skip_prefix_pool do is_expected.to be_able_to(:create, contact) end
      it "", :skip_prefix_pool do is_expected.to be_able_to(:update, contact) end
      it "", :skip_prefix_pool do is_expected.to be_able_to(:destroy, contact) end

      it "", :skip_prefix_pool do is_expected.to be_able_to(:read, client) end
      it "", :skip_prefix_pool do is_expected.to be_able_to(:create, client) end
      it "", :skip_prefix_pool do is_expected.to be_able_to(:update, client) end
      it "", :skip_prefix_pool do is_expected.to be_able_to(:destroy, client) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:transfer, client) end
      it "", :skip_prefix_pool do is_expected.to be_able_to(:read_contact_information, client) end

      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:read, prefix) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:create, prefix) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:update, prefix) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:destroy, prefix) end

      it "", :skip_prefix_pool do is_expected.to be_able_to(:read, provider_prefix) end
      it "", :skip_prefix_pool do is_expected.to be_able_to(:create, provider_prefix) end
      it "", :skip_prefix_pool do is_expected.to be_able_to(:update, provider_prefix) end
      it "", :skip_prefix_pool do is_expected.to be_able_to(:destroy, provider_prefix) end

      it "", :skip_prefix_pool do is_expected.to be_able_to(:read, doi) end
      it "", :skip_prefix_pool do is_expected.to be_able_to(:transfer, doi) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:create, doi) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:update, doi) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:destroy, doi) end
    end

    context "when is a consortium admin" do
      let(:token) do
        User.generate_token(
          role_id: "consortium_admin", provider_id: consortium.symbol.downcase,
        )
      end

      it "", :skip_prefix_pool do is_expected.to be_able_to(:read, user) end

      it "", :skip_prefix_pool do is_expected.to be_able_to(:read, consortium) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:create, consortium) end
      it "", :skip_prefix_pool do is_expected.to be_able_to(:update, consortium) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:destroy, consortium) end
      it "", :skip_prefix_pool do is_expected.to be_able_to(:read_billing_information, provider) end
      it "", :skip_prefix_pool do is_expected.to be_able_to(:read_contact_information, provider) end

      it "", :skip_prefix_pool do is_expected.to be_able_to(:read, contact) end
      it "", :skip_prefix_pool do is_expected.to be_able_to(:create, contact) end
      it "", :skip_prefix_pool do is_expected.to be_able_to(:update, contact) end
      it "", :skip_prefix_pool do is_expected.to be_able_to(:destroy, contact) end

      it "", :skip_prefix_pool do is_expected.to be_able_to(:read, consortium_contact) end
      it "", :skip_prefix_pool do is_expected.to be_able_to(:create, consortium_contact) end
      it "", :skip_prefix_pool do is_expected.to be_able_to(:update, consortium_contact) end
      it "", :skip_prefix_pool do is_expected.to be_able_to(:destroy, consortium_contact) end

      it "", :skip_prefix_pool do is_expected.to be_able_to(:read, provider) end
      it "", :skip_prefix_pool do is_expected.to be_able_to(:create, provider) end
      it "", :skip_prefix_pool do is_expected.to be_able_to(:update, provider) end
      it "", :skip_prefix_pool do is_expected.to be_able_to(:destroy, provider) end
      it "", :skip_prefix_pool do is_expected.to be_able_to(:transfer, client) end

      it "", :skip_prefix_pool do is_expected.to be_able_to(:read, client) end
      it "", :skip_prefix_pool do is_expected.to be_able_to(:create, client) end
      it "", :skip_prefix_pool do is_expected.to be_able_to(:update, client) end
      it "", :skip_prefix_pool do is_expected.to be_able_to(:destroy, client) end
      it "", :skip_prefix_pool do is_expected.to be_able_to(:read_contact_information, client) end

      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:read, prefix) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:create, prefix) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:update, prefix) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:destroy, prefix) end

      it "", :skip_prefix_pool do is_expected.to be_able_to(:read, provider_prefix) end
      it "", :skip_prefix_pool do is_expected.to be_able_to(:create, provider_prefix) end
      it "", :skip_prefix_pool do is_expected.to be_able_to(:update, provider_prefix) end
      it "", :skip_prefix_pool do is_expected.to be_able_to(:destroy, provider_prefix) end

      it "", :skip_prefix_pool do is_expected.to be_able_to(:read, doi) end
      it "", :skip_prefix_pool do is_expected.to be_able_to(:transfer, doi) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:create, doi) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:update, doi) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:destroy, doi) end
    end

    context "when is a provider user" do
      let(:token) do
        User.generate_token(
          role_id: "provider_user", provider_id: provider.symbol.downcase,
        )
      end

      it "", :skip_prefix_pool do is_expected.to be_able_to(:read, user) end

      it "", :skip_prefix_pool do is_expected.to be_able_to(:read, provider) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:create, provider) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:update, provider) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:destroy, provider) end
      it "", :skip_prefix_pool do is_expected.to be_able_to(:read_billing_information, provider) end
      it "", :skip_prefix_pool do is_expected.to be_able_to(:read_contact_information, provider) end

      it "", :skip_prefix_pool do is_expected.to be_able_to(:read, contact) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:create, contact) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:update, contact) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:destroy, contact) end

      it "", :skip_prefix_pool do is_expected.to be_able_to(:read, client) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:create, client) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:update, client) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:destroy, client) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:transfer, client) end
      it "", :skip_prefix_pool do is_expected.to be_able_to(:read_contact_information, client) end

      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:read, prefix) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:create, prefix) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:update, prefix) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:destroy, prefix) end

      it "", :skip_prefix_pool do is_expected.to be_able_to(:read, provider_prefix) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:create, provider_prefix) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:update, provider_prefix) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:destroy, provider_prefix) end

      it "", :skip_prefix_pool do is_expected.to be_able_to(:read, doi) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:transfer, doi) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:create, doi) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:update, doi) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:destroy, doi) end
    end

    context "when is a staff admin" do
      it "", :skip_prefix_pool do is_expected.to be_able_to(:read, user) end

      it "", :skip_prefix_pool do is_expected.to be_able_to(:read, provider) end
      it "", :skip_prefix_pool do is_expected.to be_able_to(:create, provider) end
      it "", :skip_prefix_pool do is_expected.to be_able_to(:update, provider) end
      it "", :skip_prefix_pool do is_expected.to be_able_to(:destroy, provider) end
      it "", :skip_prefix_pool do is_expected.to be_able_to(:transfer, client) end
      it "", :skip_prefix_pool do is_expected.to be_able_to(:read_billing_information, provider) end
      it "", :skip_prefix_pool do is_expected.to be_able_to(:read_contact_information, provider) end

      it "", :skip_prefix_pool do is_expected.to be_able_to(:read, contact) end
      it "", :skip_prefix_pool do is_expected.to be_able_to(:create, contact) end
      it "", :skip_prefix_pool do is_expected.to be_able_to(:update, contact) end
      it "", :skip_prefix_pool do is_expected.to be_able_to(:destroy, contact) end

      it "", :skip_prefix_pool do is_expected.to be_able_to(:read, client) end
      it "", :skip_prefix_pool do is_expected.to be_able_to(:create, client) end
      it "", :skip_prefix_pool do is_expected.to be_able_to(:update, client) end
      it "", :skip_prefix_pool do is_expected.to be_able_to(:destroy, client) end
      it "", :skip_prefix_pool do is_expected.to be_able_to(:read_contact_information, client) end

      it "", :skip_prefix_pool do is_expected.to be_able_to(:read, doi) end
      it "", :skip_prefix_pool do is_expected.to be_able_to(:transfer, doi) end
      it "", :skip_prefix_pool do is_expected.to be_able_to(:create, doi) end
      it "", :skip_prefix_pool do is_expected.to be_able_to(:update, doi) end
      it "", :skip_prefix_pool do is_expected.to be_able_to(:destroy, doi) end
    end

    context "when is a staff user" do
      let(:token) { User.generate_token(role_id: "staff_user") }

      it "", :skip_prefix_pool do is_expected.to be_able_to(:read, user) end

      it "", :skip_prefix_pool do is_expected.to be_able_to(:read, provider) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:create, provider) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:update, provider) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:destroy, provider) end
      it "", :skip_prefix_pool do is_expected.to be_able_to(:read_billing_information, provider) end
      it "", :skip_prefix_pool do is_expected.to be_able_to(:read_contact_information, provider) end

      it "", :skip_prefix_pool do is_expected.to be_able_to(:read, contact) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:create, contact) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:update, contact) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:destroy, contact) end

      it "", :skip_prefix_pool do is_expected.to be_able_to(:read, client) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:create, client) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:update, client) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:destroy, client) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:transfer, client) end
      it "", :skip_prefix_pool do is_expected.to be_able_to(:read_contact_information, client) end

      it "", :skip_prefix_pool do is_expected.to be_able_to(:read, doi) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:transfer, doi) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:create, doi) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:update, doi) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:destroy, doi) end
    end

    context "when is temporary" do
      let(:token) { User.generate_token(role_id: "temporary", provider_id: provider.symbol.downcase, client_id: client.symbol.downcase) }

      it "", :skip_prefix_pool do is_expected.to be_able_to(:read, user) end

      it "", :skip_prefix_pool do is_expected.to be_able_to(:read, provider) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:create, provider) end
      it "", :skip_prefix_pool do is_expected.to be_able_to(:update, provider) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:destroy, provider) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:read_billing_information, provider) end
      it "", :skip_prefix_pool do is_expected.to be_able_to(:read_contact_information, provider) end

      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:read, contact) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:create, contact) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:update, contact) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:destroy, contact) end

      it "", :skip_prefix_pool do is_expected.to be_able_to(:read, client) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:create, client) end
      it "", :skip_prefix_pool do is_expected.to be_able_to(:update, client) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:destroy, client) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:transfer, client) end
      it "", :skip_prefix_pool do is_expected.to be_able_to(:read_contact_information, client) end

      it "", :skip_prefix_pool do is_expected.to be_able_to(:read, doi) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:transfer, doi) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:create, doi) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:update, doi) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:destroy, doi) end
    end

    context "when is anonymous" do
      let(:token) { nil }

      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:create, provider) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:update, provider) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:destroy, provider) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:read_billing_information, provider) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:read_contact_information, provider) end

      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:read, contact) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:create, contact) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:update, contact) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:destroy, contact) end

      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:read, client) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:create, client) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:update, client) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:destroy, client) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:transfer, client) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:read_contact_information, client) end

      it "", :skip_prefix_pool do is_expected.to be_able_to(:read, doi) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:transfer, doi) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:create, doi) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:update, doi) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:destroy, doi) end

      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:read, prefix) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:create, prefix) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:update, prefix) end
      it "", :skip_prefix_pool do is_expected.not_to be_able_to(:destroy, prefix) end
    end
  end
end
