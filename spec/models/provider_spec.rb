require 'rails_helper'

describe Provider, type: :model do
  let(:provider)  { create(:provider) }

  describe "validations" do
    it { should validate_presence_of(:symbol) }
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:display_name) }
    it { should validate_presence_of(:system_email) }
    it { should validate_presence_of(:website) }
    it { is_expected.to strip_attribute(:name) }
    it { should allow_value("AB").for(:symbol) }
    it { should_not allow_value("A").for(:symbol) }
    it { should_not allow_value("A9").for(:symbol) }
    it { should_not allow_value("AAAAAAAAAA").for(:symbol) }
    it { expect(provider).to be_valid }
  end

  describe "admin" do
    subject { create(:provider, role_name: "ROLE_ADMIN", name: "Admin", symbol: "ADMIN") }

    it "works" do
      expect(subject.role_name).to eq("ROLE_ADMIN")
    end
  end

  describe "provider with ROLE_CONTRACTUAL_PROVIDER" do
    subject { create(:provider, role_name: "ROLE_CONTRACTUAL_PROVIDER", name: "Contractor", symbol: "CONTRCTR") }

    it "works" do
      expect(subject.role_name).to eq("ROLE_CONTRACTUAL_PROVIDER")
      expect(subject.member_type).to eq("contractual_member")
      expect(subject.member_type_label).to eq("Contractual Member")
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

  describe "non-profit status" do
    subject { build(:provider) }

    it "non-profit" do
      subject.non_profit_status = "non-profit"
      expect(subject.save).to be true
      expect(subject.errors.details).to be_empty
    end
  
    it "for-profit" do
      subject.non_profit_status = "for-profit"
      expect(subject.save).to be true
      expect(subject.errors.details).to be_empty
    end

    it "default" do
      expect(subject.save).to be true
      expect(subject.errors.details).to be_empty
      expect(subject.non_profit_status).to eq("non-profit")
    end

    it "not_supported" do
      subject.non_profit_status = "super-profit"
      expect(subject.save).to be false
      expect(subject.errors.details).to eq(:non_profit_status=>[{:error=>:inclusion, :value=>"super-profit"}])
    end
  end

  describe "salesforce id" do
    subject { build(:provider) }

    it "valid" do
      subject.salesforce_id = "abc012345678901234"
      expect(subject.save).to be true
      expect(subject.errors.details).to be_empty
    end
  
    it "invalid" do
      subject.salesforce_id = "abc"
      expect(subject.save).to be false
      expect(subject.errors.details).to eq(:salesforce_id=>[{:error=>:invalid, :value=>"abc"}])
    end

    it "blank" do
      expect(subject.save).to be true
      expect(subject.errors.details).to be_empty
      expect(subject.salesforce_id).to be_nil
    end
  end

  describe "provider with ROLE_CONSORTIUM" do
    subject { create(:provider, role_name: "ROLE_CONSORTIUM", name: "Virtual Library of Virginia", symbol: "VIVA") }

    let!(:consortium_organizations) { create_list(:provider, 3, role_name: "ROLE_CONSORTIUM_ORGANIZATION", consortium_id: subject.symbol) }

    it "works" do
      expect(subject.role_name).to eq("ROLE_CONSORTIUM")
      expect(subject.member_type).to eq("consortium_member")
      expect(subject.member_type_label).to eq("Consortium Member")
      expect(subject.consortium_organizations.length).to eq(3)
      consortium_organization = subject.consortium_organizations.last
      expect(consortium_organization.consortium_id).to eq("VIVA")
      expect(consortium_organization.member_type).to eq("consortium_organization")
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
