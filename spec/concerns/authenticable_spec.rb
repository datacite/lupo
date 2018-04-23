require 'rails_helper'

describe User, type: :model do
  let(:token) { User.generate_token }
  subject { User.new(token) }

  describe 'decode_token' do
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

  describe 'encode_token' do
    it "with name" do
      token = subject.encode_token("name" => "Josiah Carberry")
      expect(token).to start_with("eyJhbG")
    end

    it "empty string" do
      token = subject.encode_token("")
      expect(token).to be_nil
    end
  end
end

describe Provider, type: :model do
  subject { create(:provider, password_input: "12345") }

  describe 'encode_auth_param' do
    it "works" do
      credentials = subject.encode_auth_param(username: subject.symbol, password: 12345)
      expect(credentials).to start_with("VEVTVD")
    end

    it "no password" do
      subject = create(:provider)
      credentials = subject.encode_auth_param(username: subject.symbol)
      expect(credentials).to be_nil
    end
  end

  describe 'decode_auth_param' do
    it "provider" do
      expect(subject.decode_auth_param(username: subject.symbol, password: "12345")).to eq("uid"=>subject.symbol.downcase, "name"=>subject.name, "email"=>subject.contact_email, "role_id"=>"provider_admin", "provider_id"=>subject.symbol.downcase)
    end

    it "admin" do
      subject = create(:provider, symbol: "ADMIN", role_name: "ROLE_ADMIN", password_input: "12345")
      expect(subject.decode_auth_param(username: subject.symbol, password: "12345")).to eq("uid"=>subject.symbol.downcase, "name"=>subject.name, "email"=>subject.contact_email, "role_id"=>"staff_admin")
    end
  end
end

describe Client, type: :model do
  subject { create(:client, password_input: "12345") }

  describe 'decode_auth_param' do
    it "works" do
      expect(subject.decode_auth_param(username: subject.symbol, password: 12345)).to eq("uid"=>subject.symbol.downcase, "name"=>subject.name, "email"=>subject.contact_email, "password" => "12345", "role_id"=>"client_admin", "provider_id"=>subject.symbol.downcase.split(".").first, "client_id"=>subject.symbol.downcase)
    end
  end
end
