# frozen_string_literal: true

require "rails_helper"

describe Client, type: :model, prefix_pool_size: 3 do
  let!(:provider) { create(:provider) }
  let!(:client) { create(:client, provider: provider) }

  describe "Validations" do
    it { should validate_presence_of(:symbol) }
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:system_email) }
    it { is_expected.to strip_attribute(:name) }
    it { is_expected.to strip_attribute(:domains) }
  end

  describe "subjects" do
    let(:client) { build(:client,
                         provider: provider,
                         repository_type: "disciplinary"
                        )
    }
    let(:valid_subjects) do
      {
       classificationCode: "6.1",
       schemeUri: "http://www.oecd.org/science/inno/38235147.pdf",
       subject: "History and archaeology",
       subjectScheme: "Fields of Science and Technology (FOS)",
      }
    end

    it "are invalid if the repository_type is not disciplinary" do
      client.repository_type = nil
      client.subjects = [valid_subjects]
      expect(client).to_not be_valid
    end

    it "valid hash" do
      client.subjects = [valid_subjects]
      expect(client).to be_valid
      expect(client.errors.details).to be_empty
      expect(client.subjects).to eq([
        valid_subjects.with_indifferent_access
      ])
    end

    it "invalid hash if missing classificationCode" do
      client.subjects = [valid_subjects.except(:classificationCode)]
      expect(client).to_not be_valid
    end

    it "invalid hash if missing subject" do
      client.subjects = [valid_subjects.except(:subject)]
      expect(client).to_not be_valid
    end

    it "invalid hash if missing schemeUri" do
      client.subjects = [valid_subjects.except(:schemeUri)]
      expect(client).to_not be_valid
    end

    it "invalid hash if missing subjectScheme" do
      client.subjects = [valid_subjects.except(:subjectScheme)]
      expect(client).to_not be_valid
    end

    it "invalid hash if missing classificationCode" do
      client.subjects = [valid_subjects.except(:classificationCode)]
      expect(client).to_not be_valid
    end
  end

  describe "Client transfer" do
    let!(:prefixes) do
      create_list(:prefix, 10).each_with_index do |prefix, i|
        prefix.uid = "10." + (7000 + i).to_s
        prefix.save
      end
    end
    let!(:prefix) { client.prefixes.first }

    let!(:provider_prefix_more) do
      create(:provider_prefix, provider: provider, prefix: prefixes.last)
    end

    let!(:new_provider) do
      create(:provider, symbol: "QUECHUA", member_type: "direct_member")
    end
    let!(:provider_target_id) { new_provider.symbol }
    let!(:bad_provider_target_id) { "SALS" }

    context "to direct_member" do
      it "works" do
        client.transfer(provider_target_id: provider_target_id)

        expect(client.provider_id).to eq(new_provider.symbol.downcase)
        expect(new_provider.prefixes.length).to eq(1)
        expect(provider.prefixes.length).to eq(1)

        expect(new_provider.prefix_ids).to include(prefix.uid)
        expect(provider.prefix_ids).not_to include(prefix.uid)

        expect(client.prefix_ids).to include(prefix.uid)
      end

      it "it doesn't transfer" do
        client.transfer(provider_target_id: bad_provider_target_id)

        expect(client.provider_id).to eq(provider.symbol.downcase)
        expect(provider.prefixes.length).to eq(2)
        expect(provider.prefix_ids).to include(prefix.uid)
      end
    end

    context "to member_only" do
      let(:new_provider) do
        create(:provider, symbol: "QUECHUA", member_type: "member_only")
      end
      let(:provider_target_id) { new_provider.symbol }

      it "it doesn't transfer" do
        client.transfer(provider_target_id: provider_target_id)

        expect(client.provider_id).to eq(provider.symbol.downcase)
        expect(provider.prefixes.length).to eq(2)
        expect(provider.prefix_ids).to include(prefix.uid)
      end
    end

    context "to consortium_organization" do
      let(:new_provider) do
        create(
          :provider,
          symbol: "QUECHUA", member_type: "consortium_organization",
        )
      end
      let(:provider_target_id) { new_provider.symbol }

      it "works" do
        client.transfer(provider_target_id: provider_target_id)

        expect(client.provider_id).to eq(new_provider.symbol.downcase)
        expect(new_provider.prefixes.length).to eq(1)
        expect(provider.prefixes.length).to eq(1)

        expect(new_provider.prefix_ids).to include(prefix.uid)
        expect(provider.prefix_ids).not_to include(prefix.uid)
      end
    end

    context "to consortium" do
      let(:new_provider) do
        create(:provider, symbol: "QUECHUA", role_name: "ROLE_CONSORTIUM")
      end
      let(:provider_target_id) { new_provider.symbol }

      it "it doesn't transfer" do
        client.transfer(provider_target_id: provider_target_id)

        expect(client.provider_id).to eq(provider.symbol.downcase)
        expect(provider.prefixes.length).to eq(2)
        expect(provider.prefix_ids).to include(prefix.uid)
      end
    end
  end

  describe "Client prefixes transfer" do
    let!(:prefixes) do
      create_list(:prefix, 10).each_with_index do |prefix, i|
        prefix.uid = "10." + (7000 + i).to_s
        prefix.save
      end
    end
    let!(:prefix) { client.prefixes.first }

    let!(:provider_prefix_more) do
      create(:provider_prefix, provider: provider, prefix: prefixes.last)
    end

    let!(:new_provider) { create(:provider, symbol: "QUECHUA") }

    it "works" do
      client.transfer_prefixes(provider_target_id: new_provider.symbol)

      expect(new_provider.prefixes.length).to eq(1)
      expect(provider.prefixes.length).to eq(1)

      expect(new_provider.prefix_ids).to include(prefix.uid)
      expect(provider.prefix_ids).not_to include(prefix.uid)
      expect(client.prefix_ids).to include(prefix.uid)
    end
  end

  describe "methods" do
    it "should not update the symbol" do
      client.update symbol: client.symbol + "foo.bar"
      expect(client.reload.symbol).to eq(client.symbol)
    end
  end

  describe "issn" do
    let(:client) do
      build(:client, provider: provider, client_type: "periodical")
    end

    it "should support issn" do
      client.issn = { "issnl" => "1544-9173" }
      expect(client.save).to be true
      expect(client.errors.details).to be_empty
    end

    it "should support multiple issn" do
      client.issn = { "electronic" => "1544-9173", "print" => "1545-7885" }
      expect(client.save).to be true
      expect(client.errors.details).to be_empty
    end

    it "should reject invalid issn" do
      client.issn = { "issnl" => "1544-91XX" }
      expect(client.save).to be false
      expect(client.errors.details).to eq(
        issn: [{ error: "ISSN-L 1544-91XX is in the wrong format." }],
      )
    end
  end

  describe "certificate" do
    let(:client) do
      build(:client, provider: provider, client_type: "repository")
    end

    it "should support certificate" do
      client.certificate = %w[CoreTrustSeal]
      expect(client.save).to be true
      expect(client.errors.details).to be_empty
    end

    it "should support certificate" do
      client.certificate = %w[CLARIN]
      expect(client.save).to be true
      expect(client.errors.details).to be_empty
    end

    it "should support multiple certificates" do
      client.certificate = %w[WDS DSA]
      expect(client.save).to be true
      expect(client.errors.details).to be_empty
    end

    it "should reject unknown certificate" do
      client.certificate = ["MyHomeGrown Certificate"]
      expect(client.save).to be false
      expect(client.errors.details).to eq(
        certificate: [
          {
            error:
              "Certificate MyHomeGrown Certificate is not included in the list of supported certificates.",
          },
        ],
      )
    end
  end

  describe "re3data_id", vcr: true do
    subject { build(:client, re3data_id: "10.17616/R3989R") }

    it "change" do
      subject.re3data = "https://doi.org/10.17616/R3949C"
      expect(subject.save).to be true
      expect(subject.re3data_id).to eq("10.17616/R3949C")
    end

    it "change to nil" do
      subject.re3data = nil
      expect(subject.save).to be true
      expect(subject.re3data_id).to be_nil
    end
  end

  describe "salesforce id" do
    subject { build(:client) }

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

  describe "from_salesforce" do
    subject { build(:client) }

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

  describe "client_type" do
    let(:client) { build(:client, provider: provider) }

    it "repository" do
      client.client_type = "repository"
      expect(client.save).to be true
      expect(client.errors.details).to be_empty
    end

    it "periodical" do
      client.client_type = "periodical"
      expect(client.save).to be true
      expect(client.errors.details).to be_empty
    end

    it "igsnCatalog" do
      client.client_type = "igsnCatalog"
      expect(client.save).to be true
      expect(client.errors.details).to be_empty
    end

    it "raidRegistry" do
      client.client_type = "raidRegistry"
      expect(client.save).to be true
      expect(client.errors.details).to be_empty
    end

    it "unsupported" do
      client.client_type = "conference"
      expect(client.save).to be false
      expect(client.errors.details).to eq(
        client_type: [{ error: :inclusion, value: "conference" }],
      )
    end
  end

  describe "repository_type" do
    let(:client) do
      build(:client, provider: provider, client_type: "repository")
    end

    it "should support repository_type" do
      client.repository_type = %w[institutional]
      expect(client.save).to be true
      expect(client.errors.details).to be_empty
    end

    it "should support multiple repository_types" do
      client.repository_type = %w[institutional governmental]
      expect(client.save).to be true
      expect(client.errors.details).to be_empty
    end

    it "should reject unknown repository_type" do
      client.repository_type = %w[interplanetary]
      expect(client.save).to be false
      expect(client.errors.details).to eq(
        repository_type: [
          {
            error:
              "Repository type interplanetary is not included in the list of supported repository types.",
          },
        ],
      )
    end
  end

  describe "globus_uuid" do
    let(:client) { build(:client, provider: provider) }

    it "should support version 1 UUID" do
      client.globus_uuid = "6d133cee-3d3f-11ea-b77f-2e728ce88125"
      expect(client.save).to be true
      expect(client.errors.details).to be_empty
    end

    it "should support version 4 UUID" do
      client.globus_uuid = "9908a164-1e4f-4c17-ae1b-cc318839d6c8"
      expect(client.save).to be true
      expect(client.errors.details).to be_empty
    end

    it "should reject string that is not a UUID" do
      client.globus_uuid = "abc"
      expect(client.save).to be false
      expect(client.errors.details).to eq(
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
      client = create(:client, provider: provider)
      expect(client.cumulative_years).to eq((2015..Date.today.year).to_a)
    end

    it "should show years before deleted" do
      client = create(:client, provider: provider, deleted_at: "2018-06-14")
      expect(client.cumulative_years).to eq([2_015, 2_016, 2_017])
    end

    it "empty if deleted in creation year" do
      client = create(:client, provider: provider, deleted_at: "2015-06-14")
      expect(client.cumulative_years).to eq([])
    end
  end

  describe "analytics_tracking id" do
    subject { build(:client) }

    it "valid" do
      subject.analytics_tracking_id = "abc012345678901234"
      expect(subject.save).to be true
      expect(subject.errors.details).to be_empty
    end

    it "blank" do
      expect(subject.save).to be true
      expect(subject.errors.details).to be_empty
      expect(subject.analytics_tracking_id).to be_nil
    end
  end
end
