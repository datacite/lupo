# frozen_string_literal: true

require "rails_helper"

RSpec.describe DatafileController, type: :request do
  describe "GET /credentials/datafile" do
    let(:path) { "/credentials/datafile" }

    let(:bucket) { "monthly-datafile-test" }
    let(:role_arn) { "arn:aws:iam::123456789012:role/monthly-datafile-access" }

    let(:access_key_id) { "AKIA_TEST" }
    let(:secret_access_key) { "secret" }
    let(:session_token) { "session" }

    let(:headers) do
      {
        "HTTP_ACCEPT" => "application/vnd.api+json",
        "HTTP_AUTHORIZATION" => "Bearer " + bearer,
      }
    end

    let(:credentials) do
      instance_double(
        Aws::STS::Types::Credentials,
        access_key_id: access_key_id,
        secret_access_key: secret_access_key,
        session_token: session_token,
        expiration: Time.now.utc + 900,
      )
    end

    let(:assumed_role_user) do
      instance_double(
        Aws::STS::Types::AssumedRoleUser,
        assumed_role_id: "assumed-role-id",
      )
    end

    let(:sts_response) do
      instance_double(
        Aws::STS::Types::AssumeRoleResponse,
        assumed_role_user: assumed_role_user,
        credentials: credentials,
      )
    end

    let(:sts_client) { instance_double(Aws::STS::Client) }

    before do
      ENV["MONTHLY_DATAFILE_BUCKET"] = bucket
      ENV["MONTHLY_DATAFILE_ACCESS_ROLE"] = role_arn

      allow(sts_client).to receive(:assume_role).and_return(sts_response)
      allow_any_instance_of(DatafileController).to receive(:create_sts_client).and_return(sts_client)
    end

    let(:expected_success_body) do
      {
        "bucket" => bucket,
        "access_key_id" => access_key_id,
        "secret_access_key" => secret_access_key,
        "session_token" => session_token,
        "expires_in" => DatafileController::CREDENTIAL_EXPIRY_TIME,
      }
    end

    let(:expected_text_body) do
      "[datacite-datafile]\n" \
        "aws_access_key_id=#{access_key_id}\n" \
        "aws_secret_access_key=#{secret_access_key}\n" \
        "aws_session_token=#{session_token}\n"
    end

    let(:expected_unauthorized_body) do
      { "errors" => [{ "status" => "401", "title" => "Bad credentials." }] }
    end

    let(:expected_forbidden_body) do
      {
        "errors" => [
          {
            "status" => "403",
            "title" => "You are not authorized to access this resource.",
          },
        ],
      }
    end

    shared_examples "grants datafile access" do
      it "returns credentials" do
        get path, nil, headers

        expect(last_response.status).to eq(200)
        expect(json).to eq(expected_success_body)
      end
    end

    shared_examples "denies datafile access" do
      it "returns forbidden" do
        get path, nil, headers

        expect(last_response.status).to eq(403)
        expect(json).to eq(expected_forbidden_body)
      end
    end

    context "without credentials" do
      it "returns 401" do
        get path

        expect(last_response.status).to eq(401)
        expect(json).to eq(expected_unauthorized_body)
      end
    end

    context "as staff_admin" do
      let(:bearer) { User.generate_token(role_id: "staff_admin") }
      include_examples "grants datafile access"

      context "with format=text query parameter" do
        it "returns credentials in AWS shared credentials format" do
          get "#{path}?format=text", nil, headers

          expect(last_response.status).to eq(200)
          expect(last_response.content_type).to include("text/plain")
          expect(last_response.body).to eq(expected_text_body)
        end
      end

      context "with Accept: text/plain" do
        let(:headers) do
          super().merge(
            "HTTP_ACCEPT" => "text/plain",
          )
        end

        it "returns credentials in AWS shared credentials format" do
          get path, nil, headers

          expect(last_response.status).to eq(200)
          expect(last_response.content_type).to include("text/plain")
          expect(last_response.body).to eq(expected_text_body)
        end
      end
    end

    context "as staff_user" do
      let(:bearer) { User.generate_token(role_id: "staff_user") }
      include_examples "grants datafile access"
    end

    context "as consortium_admin" do
      let(:bearer) do
        User.generate_token(role_id: "consortium_admin", provider_id: "consortium")
      end

      include_examples "grants datafile access"
    end

    context "as provider_admin" do
      let(:bearer) do
        User.generate_token(role_id: "provider_admin", provider_id: "datacite")
      end

      include_examples "grants datafile access"
    end

    context "as provider_user" do
      let(:bearer) do
        User.generate_token(role_id: "provider_user", provider_id: "datacite")
      end

      include_examples "grants datafile access"
    end

    context "as client_admin (active client)" do
      let(:provider) { create(:provider) }
      let(:client) { create(:client, provider: provider, is_active: "\x01") }

      let(:bearer) do
        User.generate_token(
          role_id: "client_admin",
          uid: client.symbol,
          provider_id: provider.symbol.downcase,
          client_id: client.symbol.downcase,
        )
      end

      include_examples "grants datafile access"
    end

    context "as client_admin (inactive client)" do
      let(:provider) { create(:provider) }
      let(:client) { create(:client, provider: provider, is_active: "\x00") }

      let(:bearer) do
        User.generate_token(
          role_id: "client_admin",
          uid: client.symbol,
          provider_id: provider.symbol.downcase,
          client_id: client.symbol.downcase,
        )
      end

      include_examples "grants datafile access"
    end

    context "as client_user" do
      let(:provider) { create(:provider) }
      let(:client) { create(:client, provider: provider) }

      let(:bearer) do
        User.generate_token(
          role_id: "client_user",
          uid: client.symbol,
          provider_id: provider.symbol.downcase,
          client_id: client.symbol.downcase,
        )
      end

      include_examples "grants datafile access"
    end

    context "as user with provider_id" do
      let(:bearer) { User.generate_token(role_id: "user", provider_id: "datacite") }
      include_examples "grants datafile access"
    end

    context "as user with client_id" do
      let(:provider) { create(:provider) }
      let(:client) { create(:client, provider: provider) }

      let(:bearer) do
        User.generate_token(
          role_id: "user",
          uid: client.symbol,
          client_id: client.symbol.downcase,
        )
      end

      include_examples "grants datafile access"
    end

    context "as user without provider_id/client_id" do
      let(:bearer) { User.generate_token(role_id: "user") }
      include_examples "denies datafile access"
    end

    context "as temporary" do
      let(:bearer) { User.generate_token(role_id: "temporary") }
      include_examples "denies datafile access"
    end
  end
end
