require 'rails_helper'

describe Provider, type: :model do
  let(:provider)  { create(:provider) }

  describe "validations" do
    it { should validate_presence_of(:symbol) }
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:display_name) }
    it { should validate_presence_of(:system_email) }
    it { is_expected.to strip_attribute(:name) }
    it { expect(provider).to be_valid }
  end

  describe "admin" do
    subject { create(:provider, role_name: "ROLE_ADMIN", name: "Admin", symbol: "ADMIN") }

    it "works" do
      expect(subject.role_name).to eq("ROLE_ADMIN")
    end
  end

  describe "provider with ROLE_CONTRACTUAL_PROVIDER" do
    subject { create(:provider, role_name: "ROLE_CONTRACTUAL_PROVIDER", name: "Contractor", symbol: "CONTRACT_SLASH") }

    it "works" do
      expect(subject.role_name).to eq("ROLE_CONTRACTUAL_PROVIDER")
      expect(subject.member_type).to eq("contractual_provider")
      expect(subject.member_type_label).to eq("Contractual Provider")
    end
  end

  describe "provider with ROLE_REGISTRATION_AGENCY" do
    subject { create(:provider, role_name: "ROLE_REGISTRATION_AGENCY", name: "Crossref", symbol: "CROSSREF") }

    it "works" do
      expect(subject.role_name).to eq("ROLE_REGISTRATION_AGENCY")
      expect(subject.member_type).to eq("registration_agency")
      expect(subject.member_type_label).to eq("DOI Registration Agency")
    end
  end

  describe "provider with ROLE_CONSORTIUM_LEAD" do
    subject { create(:provider, role_name: "ROLE_CONSORTIUM_LEAD", name: "Virtual Library of Virginia", symbol: "VIVA") }

    let!(:consortium_organizations) { create_list(:provider, 3, role_name: "ROLE_CONSORTIUM_ORGANIZATION", consortium_lead_id: subject.id) }

    it "works" do
      expect(subject.role_name).to eq("ROLE_CONSORTIUM_LEAD")
      expect(subject.member_type).to eq("consortium_lead")
      expect(subject.member_type_label).to eq("Consortium Lead")
      expect(subject.consortium_organizations.length).to eq(3)
    end
  end
  
  describe "to_jsonapi" do
    it "works" do
      params = provider.to_jsonapi
      expect(params.dig("id")).to eq(provider.symbol.downcase)
      expect(params.dig("attributes","symbol")).to eq(provider.symbol)
      expect(params.dig("attributes","system-email")).to eq(provider.system_email)
      expect(params.dig("attributes","is-active")).to be true
    end
  end

  describe "password" do
    let(:password_input) { "Credible=Hangover8tighten" }
    subject { create(:provider, password_input: password_input) }

    it "should use password_input" do
      expect(subject.password).to eq(subject.encrypt_password_sha256(password_input))
    end

    it "should not use password_input when it is blank" do
      password_input = ""
      subject = create(:provider, password_input: password_input)
      expect(subject.password).to be_nil
    end
  end
end
