# frozen_string_literal: true

require "rails_helper"

describe Metadata, type: :model, vcr: true do
  let(:provider) { create(:provider, symbol: "ADMIN") }
  let(:client) { create(:client, provider: provider) }
  let(:doi) { create(:doi, client: client, aasm_state: "findable") }
  let(:xml) { file_fixture("datacite.xml").read }

  context "validations" do
    it { should validate_presence_of(:xml) }
    it { should validate_presence_of(:namespace) }
  end

  describe "clean up" do
    it("When destroy is run on metadata, remote object is deleted too", if: ENV["METADATA_STORAGE_BUCKET_NAME"].present?) do
      metadata = Metadata.create(xml: xml, doi: doi)

      saved_xml = metadata.fetch_xml_from_s3
      expect(saved_xml).not_to eq(nil)
      metadata.destroy
      saved_xml = metadata.fetch_xml_from_s3
      expect(saved_xml).to eq(nil)
    end
  end

  describe "associations" do
    it { should belong_to(:doi).with_foreign_key(:dataset).inverse_of(:metadata) }
  end

  describe "#doi_id" do
    let(:metadata) { build(:metadata, doi: doi, xml: xml) }

    it "returns the DOI ID associated with the metadata" do
      expect(metadata.doi_id).to eq(doi.doi)
    end
  end

  describe "before_validation callbacks" do
    let(:metadata) { build(:metadata, doi: doi, xml: xml) }

    it "sets the namespace before validation" do
      metadata.valid?
      expect(metadata.namespace).not_to be_nil
    end

    it "sets the metadata version before validation" do
      metadata.valid?
      expect(metadata.metadata_version).to eq(1)
    end
  end

  describe "#uid" do
    let(:metadata) { Metadata.create(xml: xml, doi: doi) }

    it "generates a uid for the metadata" do
      expect(metadata.uid).not_to be_nil
    end
  end

  describe "#client_id" do
    let(:metadata) { build(:metadata, doi: doi, xml: xml) }

    it "returns the client ID" do
      expect(metadata.client_id).to eq(client.symbol.downcase)
    end
  end

  describe "#metadata_must_be_valid" do
    context "with invalid XML" do
      let(:xml) { "invalid xml" }
      let(:metadata) { build(:metadata, doi: doi) }
      it "adds errors if XML is invalid" do
        metadata.valid?
        expect(metadata.errors[:xml]).not_to be_empty
      end
    end

    context "with valid XML" do
      let(:xml) { file_fixture("datacite.xml").read }
      let(:metadata) { build(:metadata, doi: doi, xml: xml) }

      it "does not add errors if XML is valid" do
        metadata.valid?
        expect(metadata.errors[:xml]).to be_empty
      end
    end
  end

  describe "#doi_id=" do
    let(:metadata) { build(:metadata) }

    it "sets the dataset attribute with the DOI id" do
      metadata.doi_id = doi.doi
      expect(metadata.dataset).to eq(doi.id)
    end

    it "raises ActiveRecord::RecordNotFound if DOI is not found" do
      expect { metadata.doi_id = "invalid_doi" }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  context "parses xml" do
    let(:provider) { create(:provider, symbol: "ADMIN") }
    let(:client) { create(:client, provider: provider) }
    let(:doi) { create(:doi, client: client) }
    let(:xml) { file_fixture("datacite.xml").read }

    subject { Metadata.create(xml: xml, doi: doi) }

    it "creates xml" do
      expect(subject.xml).to eq(xml)
    end

    it "valid model" do
      expect(subject.valid?).to be true
    end

    it "creates namespace" do
      expect(subject.namespace).to eq("http://datacite.org/schema/kernel-4")
    end

    it "creates metadata_version" do
      expect(subject.metadata_version).to eq(1)
    end

    it "creates doi association" do
      expect(subject.doi.doi).to eq(doi.doi)
    end
  end

  context "parses xml namespaces" do
    let(:provider) { create(:provider, symbol: "ADMIN") }
    let(:client) { create(:client, provider: provider) }
    let(:doi) { create(:doi, client: client) }
    let(:xml) { file_fixture("ns0.xml").read }

    subject { Metadata.create(xml: xml, doi: doi) }

    it "creates xml" do
      expect(subject.xml).to eq(xml)
    end

    it "valid model" do
      expect(subject.valid?).to be true
    end

    it "creates namespace" do
      expect(subject.namespace).to eq("http://datacite.org/schema/kernel-2.2")
    end

    it "creates metadata_version" do
      expect(subject.metadata_version).to eq(1)
    end

    it "creates doi association" do
      expect(subject.doi.doi).to eq(doi.doi)
    end
  end

  context "parses invalid xml draft state" do
    let(:provider) { create(:provider, symbol: "ADMIN") }
    let(:client) { create(:client, provider: provider) }
    let(:doi) { create(:doi, client: client, xml: nil) }
    let(:xml) { file_fixture("datacite_missing_creator.xml").read }

    subject { Metadata.create(xml: xml, doi: doi) }

    it "creates xml" do
      expect(subject.xml).to eq(xml)
    end

    it "creates namespace" do
      expect(subject.namespace).to eq("http://datacite.org/schema/kernel-4")
    end

    it "validates xml" do
      expect(subject.errors[:xml]).to be_empty
    end
  end
end
