# frozen_string_literal: true

require "rails_helper"

describe Provider, type: :model do
  let(:provider) { create(:provider) }

  describe "validations" do
    it { should validate_presence_of(:symbol) }
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:display_name) }
    it { should validate_presence_of(:system_email) }
    it { is_expected.to strip_attribute(:name) }
    it { should allow_value("AB").for(:symbol) }
    it { should_not allow_value("A").for(:symbol) }
    it { should_not allow_value("A9").for(:symbol) }
    it { should_not allow_value("AAAAAAAAAA").for(:symbol) }
    it { expect(provider).to be_valid }
  end

  describe "admin" do
    subject do
      create(:provider, role_name: "ROLE_ADMIN", name: "Admin", symbol: "ADMIN")
    end

    it "works" do
      expect(subject.role_name).to eq("ROLE_ADMIN")
    end
  end

  describe "provider with ROLE_CONTRACTUAL_PROVIDER" do
    subject do
      create(
        :provider,
        role_name: "ROLE_CONTRACTUAL_PROVIDER",
        name: "Contractor",
        symbol: "CONTRCTR",
      )
    end

    it "works" do
      expect(subject.role_name).to eq("ROLE_CONTRACTUAL_PROVIDER")
      expect(subject.member_type).to eq("contractual_member")
      expect(subject.member_type_label).to eq("Contractual Member")
    end
  end

  describe "provider with ROLE_DEV" do
    subject do
      create(
        :provider,
        role_name: "ROLE_DEV",
        name: "Super Developer",
        symbol: "SUPERDEV",
      )
    end

    it "works" do
      expect(subject.role_name).to eq("ROLE_DEV")
      expect(subject.member_type).to eq("developer")
      expect(subject.member_type_label).to eq("Developer")
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
      expect(subject.errors.details).to eq(
        non_profit_status: [{ error: :inclusion, value: "super-profit" }],
      )
    end
  end

  describe "logo" do
    subject { build(:provider) }

    it "with logo" do
      subject.logo =
        "data:image/png;base64," +
        Base64.strict_encode64(file_fixture("bl.png").read)
      expect(subject.save).to be true
      expect(subject.errors.details).to be_empty
      expect(subject.logo.file?).to be true
      expect(subject.logo.url).to start_with(
        "/images/members/" + subject.symbol.downcase + ".png",
      )
      expect(subject.logo.url(:medium)).to start_with(
        "/images/members/" + subject.symbol.downcase + ".png",
      )
      expect(subject.logo_url).to start_with(
        "/images/members/" + subject.symbol.downcase + ".png",
      )
      expect(subject.logo_file_name).to eq(subject.symbol.downcase + ".png")
      expect(subject.logo.content_type).to eq("image/png")
      expect(subject.logo.size).to be > 10
    end

    it "without logo" do
      subject.logo = nil
      expect(subject.save).to be true
      expect(subject.errors.details).to be_empty
      expect(subject.logo.file?).to be false
      expect(subject.logo_url).to be_nil
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
      expect(subject.errors.details).to eq(
        salesforce_id: [{ error: :invalid, value: "abc" }],
      )
    end

    it "blank" do
      expect(subject.save).to be true
      expect(subject.errors.details).to be_empty
      expect(subject.salesforce_id).to be_nil
    end
  end

  describe "doi estimate" do
    subject { build(:provider) }

    it "valid" do
      [0, 98765, "0", "98765"].each do |value|
        subject.member_type = "consortium_organization"
        subject.doi_estimate = value
        expect(subject.save).to be true
        expect(subject.doi_estimate).to be_a_kind_of(Integer)
        expect(subject.doi_estimate).to eq(value.to_i)
      end
    end

    it "invalid" do
      ["-123", -123].each do |value|
        subject.member_type = "consortium_organization"
        subject.doi_estimate = value
        expect(subject.save).to be false
        expect(subject.errors.details).to eq(
          doi_estimate: [{ count: 0, error: :greater_than_or_equal_to, value: value.to_i }]
        )
      end
    end
  end

  describe "from_salesforce" do
    subject { build(:provider) }

    it "true" do
      subject.from_salesforce = true
      expect(subject.save).to be true
      expect(subject.errors.details).to be_empty
      expect(subject.from_salesforce).to be true
    end

    it "false" do
      subject.from_salesforce = false
      expect(subject.save).to be true
      expect(subject.errors.details).to be_empty
      expect(subject.from_salesforce).to be false
    end
  end

  describe "provider with ROLE_CONSORTIUM" do
    subject do
      create(
        :provider,
        role_name: "ROLE_CONSORTIUM",
        name: "Virtual Library of Virginia",
        symbol: "VIVA",
      )
    end

    let!(:consortium_organizations) do
      create_list(
        :provider,
        3,
        role_name: "ROLE_CONSORTIUM_ORGANIZATION",
        consortium_id: subject.symbol,
      )
    end

    it "works" do
      expect(subject.role_name).to eq("ROLE_CONSORTIUM")
      expect(subject.member_type).to eq("consortium")
      expect(subject.member_type_label).to eq("Consortium")
      expect(subject.consortium_organizations.length).to eq(3)
      consortium_organization = subject.consortium_organizations.last
      expect(consortium_organization.consortium_id).to eq("VIVA")
      expect(consortium_organization.member_type).to eq(
        "consortium_organization",
      )
    end
  end

  describe "provider with ROLE_CONSORTIUM_ORGANIZATION" do
    let(:consortium) do
      create(
        :provider,
        role_name: "ROLE_CONSORTIUM",
        name: "Virtual Library of Virginia",
        symbol: "VIVA",
      )
    end

    subject do
      create(
        :provider,
        name: "University of Virginia",
        role_name: "ROLE_CONSORTIUM_ORGANIZATION",
        consortium_id: consortium.symbol,
      )
    end

    it "works" do
      expect(subject.role_name).to eq("ROLE_CONSORTIUM_ORGANIZATION")
      expect(subject.member_type).to eq("consortium_organization")
      expect(subject.member_type_label).to eq("Consortium Organization")
      expect(subject.consortium.name).to eq("Virtual Library of Virginia")
      expect(subject.consortium.symbol).to eq("VIVA")
      expect(subject.consortium.member_type).to eq("consortium")
    end
  end

  describe "to_jsonapi" do
    xit "works" do
      params = provider.to_jsonapi
      expect(params.dig("id")).to eq(provider.symbol.downcase)
      expect(params.dig("attributes", "symbol")).to eq(provider.symbol)
      expect(params.dig("attributes", "system-email")).to eq(
        provider.system_email,
      )
      expect(params.dig("attributes", "is-active")).to be true
    end
  end

  describe "password" do
    let(:password_input) { "Credible=Hangover8tighten" }
    subject { create(:provider, password_input: password_input) }

    it "should use password_input" do
      expect(subject.password).to eq(
        subject.encrypt_password_sha256(password_input),
      )
    end

    it "should not use password_input when it is blank" do
      password_input = ""
      subject = create(:provider, password_input: password_input)
      expect(subject.password).to be_nil
    end
  end

  describe "globus_uuid" do
    let(:provider) { build(:provider) }

    it "should support version 1 UUID" do
      provider.globus_uuid = "6d133cee-3d3f-11ea-b77f-2e728ce88125"
      expect(provider.save).to be true
      expect(provider.errors.details).to be_empty
    end

    it "should support version 4 UUID" do
      provider.globus_uuid = "9908a164-1e4f-4c17-ae1b-cc318839d6c8"
      expect(provider.save).to be true
      expect(provider.errors.details).to be_empty
    end

    it "should reject string that is not a UUID" do
      provider.globus_uuid = "abc"
      expect(provider.save).to be false
      expect(provider.errors.details).to eq(
        globus_uuid: [{ error: "abc is not a valid UUID" }],
      )
    end
  end

  describe "cumulative_years" do
    before(:each) do
      allow(Time).to receive(:now).and_return(Time.mktime(2_015, 4, 8))
      allow(Time.zone).to receive(:now).and_return(Time.mktime(2_015, 4, 8))
    end

    it "should show all cumulative years" do
      provider = create(:provider)
      expect(provider.cumulative_years).to eq(
        [2_015, 2_016, 2_017, 2_018, 2_019, 2_020, 2_021, 2_022, 2_023, 2_024, 2_025],
      )
    end

    it "should show years before deleted" do
      provider = create(:provider, deleted_at: "2018-06-14")
      expect(provider.cumulative_years).to eq([2_015, 2_016, 2_017])
    end

    it "empty if deleted in creation year" do
      provider = create(:provider, deleted_at: "2015-06-14")
      expect(provider.cumulative_years).to eq([])
    end
  end

  describe "activities" do
    subject { build(:provider) }

    it "is valid" do
      expect(subject.save).to be true
      expect(subject.errors.details).to be_empty
      expect(subject.activities.length).to eq(1)
      activity = subject.activities.first
      expect(activity.audited_changes["non_profit_status"]).to eq("non-profit")
    end
  end
end
