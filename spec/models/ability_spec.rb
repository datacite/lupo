# frozen_string_literal: true

require "rails_helper"
require "cancan/matchers"

describe User, type: :model, elasticsearch: false, skip_prefix_pool: true do
  let(:token) { User.generate_token }
  let(:user) { User.new(token) }
  let(:consortium) { build_stubbed(:provider, role_name: "ROLE_CONSORTIUM") }
  let(:provider) do
    build_stubbed(
      :provider,
      consortium: consortium, role_name: "ROLE_CONSORTIUM_ORGANIZATION",
    )
  end
  let(:contact) { build_stubbed(:contact, provider: provider) }
  let(:consortium_contact) { build_stubbed(:contact, provider: consortium) }
  let(:prefix) { build_stubbed(:prefix, uid: "10.14454") }
  let(:client) { build(:client, provider: provider) }
  let(:provider_prefix) do
    build_stubbed(:provider_prefix, provider: provider, prefix: prefix)
  end
  let(:client_prefix) do
    build_stubbed(:client_prefix, client: client, prefix: prefix)
  end
  let(:doi) { build_stubbed(:doi, client: client) }
  let(:media) { build_stubbed(:media, doi: doi) }
  let(:xml) { file_fixture("datacite.xml").read }
  let(:metadata) { build_stubbed(:metadata, xml: xml, doi: doi) }

  describe "User attributes", order: :defined, skip_prefix_pool: true do
    it "is valid with valid attributes" do
      expect(user.name).to eq("Josiah Carberry")
      expect(user.role_id).to eq("staff_admin")
    end
  end

  describe "abilities", vcr: true,  skip_prefix_pool: true do
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

      let(:consortium) { create(:provider, role_name: "ROLE_CONSORTIUM") }
      let(:provider) do
        create(
          :provider,
          consortium: consortium, role_name: "ROLE_CONSORTIUM_ORGANIZATION",
        )
      end
      let!(:prefix) { create(:prefix, uid: "10.14454") }
      let!(:provider_prefix) { create(:provider_prefix, provider: provider, prefix: prefix) }
      let(:client) { create(:client, provider: provider) }
      let!(:client_prefix) { create(:client_prefix, client: client, prefix: prefix) }
      let(:token) do
        User.generate_token({
          role_id: "client_admin",
          provider_id: provider.symbol.downcase,
          client_id: client.symbol.downcase,
        })
      end

      it "can read the user" do
        is_expected.to be_able_to(:read, user)
      end

      it "can read, but not create/update/destroy/read_billing_information/read_contact_information of a provider" do
        is_expected.to be_able_to(:read, provider)
        is_expected.not_to be_able_to(:create, provider)
        is_expected.not_to be_able_to(:update, provider)
        is_expected.not_to be_able_to(:destroy, provider)
        is_expected.not_to be_able_to(:read_billing_information, provider)
        is_expected.not_to be_able_to(:read_contact_information, provider)
      end

      it "can not read/create/update/destroy a contact" do
        is_expected.not_to be_able_to(:read, contact)
        is_expected.not_to be_able_to(:create, contact)
        is_expected.not_to be_able_to(:update, contact)
        is_expected.not_to be_able_to(:destroy, contact)
      end


      it "can read/update/read_contact_information/read_analytics but not create/destroy/transfer the client" do
        is_expected.to be_able_to(:read, client)
        is_expected.to be_able_to(:update, client)
        is_expected.to be_able_to(:read_contact_information, client)
        is_expected.to be_able_to(:read_analytics, client)
        is_expected.not_to be_able_to(:create, client)
        is_expected.not_to be_able_to(:destroy, client)
        is_expected.not_to be_able_to(:transfer, client)
      end

      it "can not read/create/update/destroy the prefix" do
        is_expected.not_to be_able_to(:read, prefix)
        is_expected.not_to be_able_to(:create, prefix)
        is_expected.not_to be_able_to(:update, prefix)
        is_expected.not_to be_able_to(:destroy, prefix)
      end

      it "can read but not create/update/destroy the client prefix" do
        is_expected.to be_able_to(:read, client_prefix)
        is_expected.not_to be_able_to(:create, client_prefix)
        is_expected.not_to be_able_to(:update, client_prefix)
        is_expected.not_to be_able_to(:destroy, client_prefix)
      end

      it "can read/create/update/destroy but not transfer the doi" do
        is_expected.to be_able_to(:read, doi)
        is_expected.to be_able_to(:create, doi)
        is_expected.to be_able_to(:update, doi)
        is_expected.to be_able_to(:destroy, doi)
        is_expected.not_to be_able_to(:transfer, doi)
      end
    end

    context "when is a client admin inactive" do

      let(:consortium) { create(:provider, role_name: "ROLE_CONSORTIUM") }
      let(:provider) do
        create(
          :provider,
          consortium: consortium, role_name: "ROLE_CONSORTIUM_ORGANIZATION",
        )
      end
      let!(:prefix) { create(:prefix, uid: "10.14454") }
      let!(:provider_prefix) { create(:provider_prefix, provider: provider, prefix: prefix) }
      let(:client) do
        create(:client, {
          provider: provider,
          is_active: false
        })

      end
      let!(:client_prefix) { create(:client_prefix, client: client, prefix: prefix) }
      let(:token) do
        User.generate_token({
          role_id: "client_admin",
          provider_id: provider.symbol.downcase,
          client_id: client.symbol.downcase,
        })
      end

      it "can read the user" do
        is_expected.to be_able_to(:read, user)
      end

      it "can read, but not create/update/destroy/read_billing_information/read_contact_information of a provider" do
        is_expected.to be_able_to(:read, provider)
        is_expected.not_to be_able_to(:create, provider)
        is_expected.not_to be_able_to(:update, provider)
        is_expected.not_to be_able_to(:destroy, provider)
        is_expected.not_to be_able_to(:read_billing_information, provider)
        is_expected.not_to be_able_to(:read_contact_information, provider)
      end

      it "can not read/create/update/destroy a contact" do
        is_expected.not_to be_able_to(:read, contact)
        is_expected.not_to be_able_to(:create, contact)
        is_expected.not_to be_able_to(:update, contact)
        is_expected.not_to be_able_to(:destroy, contact)
      end

      it "can read/read_contact_information/read_analytics but not create/update/destroy/transfer the client" do
        is_expected.to be_able_to(:read, client)
        is_expected.not_to be_able_to(:create, client)
        is_expected.not_to be_able_to(:update, client)
        is_expected.not_to be_able_to(:destroy, client)
        is_expected.not_to be_able_to(:transfer, client)
        is_expected.to be_able_to(:read_contact_information, client)
        is_expected.to be_able_to(:read_analytics, client)
      end

      it "can not read/create/update/destroy the prefix" do
        is_expected.not_to be_able_to(:read, prefix)
        is_expected.not_to be_able_to(:create, prefix)
        is_expected.not_to be_able_to(:update, prefix)
        is_expected.not_to be_able_to(:destroy, prefix)
      end

      it "can read but not create/update/destroy the client prefix"do
        is_expected.to be_able_to(:read, client_prefix)
        is_expected.not_to be_able_to(:create, client_prefix)
        is_expected.not_to be_able_to(:update, client_prefix)
        is_expected.not_to be_able_to(:destroy, client_prefix)
      end

      it "can read but not transfer/create/update/destroy the doi" do
        is_expected.to be_able_to(:read, doi)
        is_expected.not_to be_able_to(:transfer, doi)
        is_expected.not_to be_able_to(:create, doi)
        is_expected.not_to be_able_to(:update, doi)
        is_expected.not_to be_able_to(:destroy, doi)
      end
    end

    context "when is a client user" do

      let(:consortium) { create(:provider, role_name: "ROLE_CONSORTIUM") }
      let(:provider) do
        create(
          :provider,
          consortium: consortium, role_name: "ROLE_CONSORTIUM_ORGANIZATION",
        )
      end
      let!(:prefix) { create(:prefix, uid: "10.14454") }
      let!(:provider_prefix) { create(:provider_prefix, provider: provider, prefix: prefix) }
      let(:client) { create(:client, provider: provider) }
      let!(:client_prefix) { create(:client_prefix, client: client, prefix: prefix) }
      let(:token) do
        User.generate_token({
          role_id: "client_user",
          provider_id: provider.symbol.downcase,
          client_id: client.symbol.downcase,
        })
      end

      it do
        is_expected.to be_able_to(:read, user)
      end

      it do
        is_expected.to be_able_to(:read, provider)
        is_expected.not_to be_able_to(:create, provider)
        is_expected.not_to be_able_to(:update, provider)
        is_expected.not_to be_able_to(:destroy, provider)
        is_expected.not_to be_able_to(:read_billing_information, provider)
        is_expected.not_to be_able_to(:read_contact_information, provider)
      end

      it do
        is_expected.not_to be_able_to(:read, contact)
        is_expected.not_to be_able_to(:create, contact)
        is_expected.not_to be_able_to(:update, contact)
        is_expected.not_to be_able_to(:destroy, contact)
      end

      it do
        is_expected.to be_able_to(:read, client)
        is_expected.not_to be_able_to(:create, client)
        is_expected.not_to be_able_to(:update, client)
        is_expected.not_to be_able_to(:destroy, client)
        is_expected.not_to be_able_to(:transfer, client)
        is_expected.to be_able_to(:read_contact_information, client)
        is_expected.to be_able_to(:read_analytics, client)
      end

      it do
        is_expected.not_to be_able_to(:read, prefix)
        is_expected.not_to be_able_to(:create, prefix)
        is_expected.not_to be_able_to(:update, prefix)
        is_expected.not_to be_able_to(:destroy, prefix)
      end

      it do
        is_expected.to be_able_to(:read, client_prefix)
        is_expected.not_to be_able_to(:create, client_prefix)
        is_expected.not_to be_able_to(:update, client_prefix)
        is_expected.not_to be_able_to(:destroy, client_prefix)
      end

      it do
        is_expected.to be_able_to(:read, doi)
        is_expected.not_to be_able_to(:transfer, doi)
        is_expected.not_to be_able_to(:create, doi)
        is_expected.not_to be_able_to(:update, doi)
        is_expected.not_to be_able_to(:destroy, doi)
      end
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
          role_id: "provider_user",
          provider_id: provider.symbol.downcase,
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

      let(:consortium) { create(:provider, role_name: "ROLE_CONSORTIUM") }
      let(:provider) { create(:provider, consortium: consortium, role_name: "ROLE_CONSORTIUM_ORGANIZATION") }
      let!(:prefix) { create(:prefix, uid: "10.14454") }
      let!(:provider_prefix) { create(:provider_prefix, provider: provider, prefix: prefix) }
      let(:client) { create(:client, provider: provider) }
      let!(:client_prefix) { create(:client_prefix, client: client, prefix: prefix) }
      let(:token) do
        User.generate_token(
          role_id: "staff_admin",
          provider_id: provider.symbol.downcase,
          client_id: client.symbol.downcase,
        )
      end

      it "can read the user" do
        is_expected.to be_able_to(:read, user)
      end

      it 'can read/create/update/destroy/transfer/read_billing_information/read_contact_information the provider' do
        is_expected.to be_able_to(:read, provider)
        is_expected.to be_able_to(:create, provider)
        is_expected.to be_able_to(:update, provider)
        is_expected.to be_able_to(:destroy, provider)
        is_expected.to be_able_to(:transfer, client)
        is_expected.to be_able_to(:read_billing_information, provider)
        is_expected.to be_able_to(:read_contact_information, provider)
      end

      it "can read/create/update/destroy the contact" do
        is_expected.to be_able_to(:read, contact)
        is_expected.to be_able_to(:create, contact)
        is_expected.to be_able_to(:update, contact)
        is_expected.to be_able_to(:destroy, contact)
      end

      it "can read/create/update/destroy/read_contact_information/read_analytics the client" do
        is_expected.to be_able_to(:read, client)
        is_expected.to be_able_to(:create, client)
        is_expected.to be_able_to(:update, client)
        is_expected.to be_able_to(:destroy, client)
        is_expected.to be_able_to(:read_contact_information, client)
        is_expected.to be_able_to(:read_analytics, client)
      end

      it "can read/transfer/create/update/destroy doi" do
        is_expected.to be_able_to(:read, doi)
        is_expected.to be_able_to(:transfer, doi)
        is_expected.to be_able_to(:create, doi)
        is_expected.to be_able_to(:update, doi)
        is_expected.to be_able_to(:destroy, doi)
      end
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
      let(:token) do
        User.generate_token({
          role_id: "temporary",
          provider_id: provider.symbol.downcase,
          client_id: client.symbol.downcase,
        })
      end

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
