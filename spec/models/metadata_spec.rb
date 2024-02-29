# frozen_string_literal: true

require "rails_helper"

describe Metadata, type: :model, vcr: true do
  context "validations" do
    it { should validate_presence_of(:xml) }
    it { should validate_presence_of(:namespace) }
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
      # TODO:: Fix this last!!!
      # expect(subject.xml).to eq(xml)
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
