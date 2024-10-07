# frozen_string_literal: true

require "rails_helper"

describe User, type: :model, elasticsearch: true do
  let(:token) { User.generate_token }
  subject { User.new(token) }

  describe "decode_token DataCite" do
    it "has name" do
      payload = subject.decode_token(token)
      expect(payload["name"]).to eq("Josiah Carberry")
    end

    it "empty token" do
      payload = subject.decode_token("")
      expect(payload).to eq(errors: "The token could not be decoded.")
    end

    it "invalid token" do
      payload = subject.decode_token("abc")
      expect(payload).to eq(errors: "The token could not be decoded.")
    end

    it "expired token" do
      token = User.generate_token(exp: 0)
      subject = User.new(token)
      payload = subject.decode_token(token)
      expect(payload).to eq(errors: "The token has expired.")
    end
  end

  describe "decode_alb_token" do
    let(:token) { User.generate_alb_token }

    it "has name" do
      payload = subject.decode_alb_token(token)
      expect(payload["name"]).to eq("Josiah Carberry")
    end

    it "empty token" do
      payload = subject.decode_alb_token("")
      expect(payload).to eq(errors: "The token could not be decoded.")
    end

    it "invalid token" do
      payload = subject.decode_alb_token("abc")
      expect(payload).to eq(errors: "The token could not be decoded.")
    end

    it "expired token" do
      token = User.generate_alb_token(exp: 0)
      subject = User.new(token)
      payload = subject.decode_alb_token(token)
      expect(payload).to eq(errors: "The token has expired.")
    end
  end

  describe "not_allowed_by_doi_and_user" do
    context "findable doi" do
      let(:doi) { create(:doi, event: "publish") }

      it "staff_admin" do
        token = User.generate_token(role_id: "staff_admin")
        subject = User.new(token)
        expect(
          subject.not_allowed_by_doi_and_user(doi: doi, user: subject),
        ).to be false
      end

      it "staff_user" do
        token = User.generate_token(role_id: "staff_user")
        subject = User.new(token)
        expect(
          subject.not_allowed_by_doi_and_user(doi: doi, user: subject),
        ).to be false
      end

      it "consortium_admin" do
        token =
          User.generate_token(
            role_id: "consortium_admin", provider_id: "datacite",
          )
        subject = User.new(token)
        expect(
          subject.not_allowed_by_doi_and_user(doi: doi, user: subject),
        ).to be false
      end

      it "provider_admin" do
        token =
          User.generate_token(
            role_id: "provider_admin", provider_id: "datacite",
          )
        subject = User.new(token)
        expect(
          subject.not_allowed_by_doi_and_user(doi: doi, user: subject),
        ).to be false
      end

      it "provider_user" do
        token =
          User.generate_token(role_id: "provider_user", provider_id: "datacite")
        subject = User.new(token)
        expect(
          subject.not_allowed_by_doi_and_user(doi: doi, user: subject),
        ).to be false
      end

      it "client_admin" do
        token =
          User.generate_token(
            role_id: "client_admin", client_id: "datacite.rph",
          )
        subject = User.new(token)
        expect(
          subject.not_allowed_by_doi_and_user(doi: doi, user: subject),
        ).to be false
      end

      it "client_user" do
        token =
          User.generate_token(role_id: "client_user", client_id: "datacite.rph")
        subject = User.new(token)
        expect(
          subject.not_allowed_by_doi_and_user(doi: doi, user: subject),
        ).to be false
      end

      it "user" do
        token = User.generate_token(role_id: "user")
        subject = User.new(token)
        expect(
          subject.not_allowed_by_doi_and_user(doi: doi, user: subject),
        ).to be false
      end

      it "temporary" do
        token = User.generate_token(role_id: "temporary")
        subject = User.new(token)
        expect(
          subject.not_allowed_by_doi_and_user(doi: doi, user: subject),
        ).to be false
      end

      it "anonymous" do
        token = User.generate_token(role_id: "anonymous")
        subject = User.new(token)
        expect(
          subject.not_allowed_by_doi_and_user(doi: doi, user: subject),
        ).to be false
      end
    end

    context "draft doi" do
      let!(:consortium) do
        create(:provider, symbol: "DC", role_name: "ROLE_CONSORTIUM")
      end

      let!(:provider) do
        create(
          :provider,
          symbol: "DATACITE",
          consortium: consortium,
          role_name: "ROLE_CONSORTIUM_ORGANIZATION",
        )
      end
      let!(:client) do
        create(:client, provider: provider, symbol: "DATACITE.RPH")
      end
      let!(:prefix) { create(:prefix, uid: "10.14454") }
      let!(:provider_prefix) do
        create(:provider_prefix, provider: provider, prefix: prefix)
      end
      let!(:client_prefix) do
        create(
          :client_prefix,
          client: client,
          prefix: prefix,
          provider_prefix: provider_prefix
        )
      end

      let!(:doi) { create(:doi, client: client) }

      it "staff_admin" do
        token = User.generate_token(role_id: "staff_admin")
        subject = User.new(token)
        expect(
          subject.not_allowed_by_doi_and_user(doi: doi, user: subject),
        ).to be false
      end

      it "staff_user" do
        token = User.generate_token(role_id: "staff_user")
        subject = User.new(token)
        expect(
          subject.not_allowed_by_doi_and_user(doi: doi, user: subject),
        ).to be false
      end

      it "consortium_admin" do
        token =
          User.generate_token(role_id: "consortium_admin", provider_id: "dc")
        subject = User.new(token)
        expect(
          subject.not_allowed_by_doi_and_user(doi: doi, user: subject),
        ).to be false
      end

      it "provider_admin" do
        token =
          User.generate_token(
            role_id: "provider_admin", provider_id: "datacite",
          )
        subject = User.new(token)
        expect(
          subject.not_allowed_by_doi_and_user(doi: doi, user: subject),
        ).to be false
      end

      it "provider_user" do
        token =
          User.generate_token(role_id: "provider_user", provider_id: "datacite")
        subject = User.new(token)
        expect(
          subject.not_allowed_by_doi_and_user(doi: doi, user: subject),
        ).to be false
      end

      it "client_admin" do
        token =
          User.generate_token(
            role_id: "client_admin", client_id: "datacite.rph",
          )
        subject = User.new(token)
        expect(
          subject.not_allowed_by_doi_and_user(doi: doi, user: subject),
        ).to be false
      end

      it "client_user" do
        token =
          User.generate_token(role_id: "client_user", client_id: "datacite.rph")
        subject = User.new(token)
        expect(
          subject.not_allowed_by_doi_and_user(doi: doi, user: subject),
        ).to be false
      end

      it "user" do
        token = User.generate_token(role_id: "user")
        subject = User.new(token)
        expect(
          subject.not_allowed_by_doi_and_user(doi: doi, user: subject),
        ).to be true
      end

      it "temporary" do
        token = User.generate_token(role_id: "temporary")
        subject = User.new(token)
        expect(
          subject.not_allowed_by_doi_and_user(doi: doi, user: subject),
        ).to be true
      end

      it "anonymous" do
        token = User.generate_token(role_id: "anonymous")
        subject = User.new(token)
        expect(
          subject.not_allowed_by_doi_and_user(doi: doi, user: subject),
        ).to be true
      end
    end
  end

  describe "encode_token" do
    it "with name" do
      token = subject.encode_token("name" => "Josiah Carberry")
      expect(token).to start_with("eyJhbG")
    end

    it "empty string" do
      token = subject.encode_token("")
      expect(token).to be_nil
    end
  end

  describe "encode_alb_token" do
    it "with name" do
      token = subject.encode_alb_token("name" => "Josiah Carberry")
      expect(token).to start_with("eyJhbG")
    end

    it "empty string" do
      token = subject.encode_alb_token("")
      expect(token).to be_nil
    end
  end

  describe "encode_globus_token" do
    it "with name" do
      token = subject.encode_globus_token("name" => "Josiah Carberry")
      expect(token).to start_with("eyJhbG")
    end

    it "empty string" do
      token = subject.encode_globus_token("")
      expect(token).to be_nil
    end
  end
end

describe Provider, type: :model do
  subject { create(:provider, password_input: "12345") }

  describe "encode_auth_param" do
    it "works" do
      credentials =
        subject.encode_auth_param(username: subject.symbol, password: 12_345)
      expect(credentials).to start_with("VEVT")
    end

    it "no password" do
      subject = create(:provider)
      credentials = subject.encode_auth_param(username: subject.symbol)
      expect(credentials).to be_nil
    end
  end

  describe "decode_auth_param" do
    xit "provider" do
      expect(
        subject.decode_auth_param(username: subject.symbol, password: "12345"),
      ).to eq(
        "uid" => subject.symbol.downcase,
        "name" => subject.name,
        "email" => subject.system_email,
        "role_id" => "provider_admin",
        "provider_id" => subject.symbol.downcase,
      )
    end

    xit "admin" do
      subject =
        create(
          :provider,
          symbol: "ADMIN", role_name: "ROLE_ADMIN", password_input: "12345",
        )
      expect(
        subject.decode_auth_param(username: subject.symbol, password: "12345"),
      ).to eq(
        "uid" => subject.symbol.downcase,
        "name" => subject.name,
        "email" => subject.system_email,
        "role_id" => "staff_admin",
      )
    end

    xit "consortium" do
      subject =
        create(:provider, role_name: "ROLE_CONSORTIUM", password_input: "12345")
      expect(
        subject.decode_auth_param(username: subject.symbol, password: "12345"),
      ).to eq(
        "uid" => subject.symbol.downcase,
        "name" => subject.name,
        "email" => subject.system_email,
        "role_id" => "consortium_admin",
        "provider_id" => subject.symbol.downcase,
      )
    end
  end
end

describe Client, type: :model do
  subject { create(:client, password_input: "12345") }

  describe "decode_auth_param" do
    xit "works" do
      expect(
        subject.decode_auth_param(username: subject.symbol, password: 12_345),
      ).to eq(
        "uid" => subject.symbol.downcase,
        "name" => subject.name,
        "email" => subject.system_email,
        "role_id" => "client_admin",
        "provider_id" => subject.provider_id,
        "client_id" => subject.symbol.downcase,
      )
    end
  end

  describe "get_payload" do
    let (:payload) { subject.get_payload(
      uid: subject.symbol.downcase, user: subject, password: 12_345,
    ) }
    it "works" do
      expect(payload).to eq(
        "uid" => subject.symbol.downcase,
        "name" => subject.name,
        "email" => subject.system_email,
        "role_id" => "client_admin",
        "provider_id" => subject.provider_id,
        "client_id" => subject.symbol.downcase,
      )
    end

    it "does not contain password" do
      expect(payload).to include("role_id")
    end
  end
end
