require 'rails_helper'

describe Metadata, type: :model, vcr: true do
  context "validations" do
    it { should validate_presence_of(:xml) }
    it { should validate_presence_of(:namespace) }
  end

  context "parses xml" do
    let(:provider)  { create(:provider, symbol: "ADMIN") }
    let(:client)  { create(:client, provider: provider) }
    let(:doi) { create(:doi, doi: "10.5256/f1000research.8570.r6420", client: client) }
    let(:xml) { "PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiIHN0YW5kYWxvbmU9InllcyI/PjxyZXNvdXJjZSB4c2k6c2NoZW1hTG9jYXRpb249Imh0dHA6Ly9kYXRhY2l0ZS5vcmcvc2NoZW1hL2tlcm5lbC0zIGh0dHA6Ly9zY2hlbWEuZGF0YWNpdGUub3JnL21ldGEva2VybmVsLTMvbWV0YWRhdGEueHNkIiB4bWxucz0iaHR0cDovL2RhdGFjaXRlLm9yZy9zY2hlbWEva2VybmVsLTMiIHhtbG5zOnhzaT0iaHR0cDovL3d3dy53My5vcmcvMjAwMS9YTUxTY2hlbWEtaW5zdGFuY2UiPjxpZGVudGlmaWVyIGlkZW50aWZpZXJUeXBlPSJET0kiPjEwLjUyNTYvZjEwMDByZXNlYXJjaC44NTcwLnI2NDIwPC9pZGVudGlmaWVyPjxjcmVhdG9ycz48Y3JlYXRvcj48Y3JlYXRvck5hbWU+ZCBzPC9jcmVhdG9yTmFtZT48L2NyZWF0b3I+PC9jcmVhdG9ycz48dGl0bGVzPjx0aXRsZT5SZWZlcmVlIHJlcG9ydC4gRm9yOiBSRVNFQVJDSC0zNDgyIFt2ZXJzaW9uIDU7IHJlZmVyZWVzOiAxIGFwcHJvdmVkLCAxIGFwcHJvdmVkIHdpdGggcmVzZXJ2YXRpb25zXTwvdGl0bGU+PC90aXRsZXM+PHB1Ymxpc2hlcj5GMTAwMCBSZXNlYXJjaCBMaW1pdGVkPC9wdWJsaXNoZXI+PHB1YmxpY2F0aW9uWWVhcj4yMDE3PC9wdWJsaWNhdGlvblllYXI+PHJlc291cmNlVHlwZSByZXNvdXJjZVR5cGVHZW5lcmFsPSJUZXh0Ii8+PC9yZXNvdXJjZT4=" }

    subject { Metadata.create(xml: xml, doi: doi) }

    it "creates xml" do
      doc = Nokogiri::XML(subject.xml, nil, 'UTF-8', &:noblanks)
      expect(doc.at_css("identifier").content).to eq(doi.doi.downcase)
    end

    it "valid model" do
      expect(subject.valid?).to be true
    end

    it "creates namespace" do
      expect(subject.namespace).to eq("http://datacite.org/schema/kernel-3")
    end

    it "creates metadata_version" do
      expect(subject.metadata_version).to eq(1)
    end

    it "creates doi association" do
      expect(subject.doi.doi).to eq(doi.doi)
    end
  end

  context "parses invalid xml draft state" do
    let(:provider)  { create(:provider, symbol: "ADMIN") }
    let(:client)  { create(:client, provider: provider) }
    let(:doi) { create(:doi, doi: "10.5438/4k3m-nyvg", client: client) }
    let(:xml) { ::Base64.strict_encode64(file_fixture('datacite_missing_creator.xml').read) }

    subject { Metadata.create(xml: xml, doi: doi) }

    it "creates xml" do
      doc = Nokogiri::XML(subject.xml, nil, 'UTF-8', &:noblanks)
      expect(doc.at_css("identifier").content).to eq(doi.doi)
    end

    it "creates namespace" do
      expect(subject.namespace).to eq("http://datacite.org/schema/kernel-4")
    end

    it "valid model" do
      expect(subject.valid?).to be true
    end

    it "validates xml" do
      expect(subject.errors[:xml]).to be_empty
    end
  end

  context "parses invalid xml findable state" do
    let(:provider)  { create(:provider, symbol: "ADMIN") }
    let(:client)  { create(:client, provider: provider) }
    let(:doi) { create(:doi, doi: "10.5438/4k3m-nyvg", client: client, aasm_state: "findable") }
    let(:xml) { ::Base64.strict_encode64(file_fixture('datacite_missing_creator.xml').read) }
    subject { Metadata.new(xml: xml, doi: doi) }

    it "creates xml" do
      doc = Nokogiri::XML(subject.xml, nil, 'UTF-8', &:noblanks)
      expect(doc.at_css("identifier").content).to eq(doi.doi)
    end

    it "creates namespace" do
      subject.valid?
      expect(subject.namespace).to eq("http://datacite.org/schema/kernel-4")
    end

    it "valid model" do
      expect(subject.valid?).to be false
    end

    it "validates xml" do
      subject.valid?
      expect(subject.errors[:creators]).to eq(["Missing child element(s). Expected is ( {http://datacite.org/schema/kernel-4}creator )."])
    end

    it "validation_errors" do
      expect(subject.validation_errors).to eq([{:source=>"creators", :title=>"Missing child element(s). Expected is ( {http://datacite.org/schema/kernel-4}creator )."}])
    end
  end

  context "parses Crossref xml" do
    let(:provider)  { create(:provider, symbol: "ADMIN") }
    let(:client)  { create(:client, provider: provider) }
    let(:doi) { create(:doi, doi: "10.1371/journal.pone.0000030", client: client) }
    let(:xml) { ::Base64.strict_encode64(file_fixture('crossref.xml').read) }

    subject { Metadata.create(xml: xml, doi: doi) }

    it "creates xml" do
      doc = Nokogiri::XML(subject.xml, nil, 'UTF-8', &:noblanks)
      expect(doc.at_css("identifier").content).to eq(doi.doi.downcase)
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

  context "parses schema 3" do
    let(:provider)  { create(:provider, symbol: "ADMIN") }
    let(:client)  { create(:client, provider: provider) }
    let(:doi) { create(:doi, doi: "10.5061/dryad.8515", client: client) }
    let(:xml) { ::Base64.strict_encode64(file_fixture('datacite_schema_3.xml').read) }

    subject { Metadata.create(xml: xml, doi: doi) }

    it "creates xml" do
      doc = Nokogiri::XML(subject.xml, nil, 'UTF-8', &:noblanks)
      expect(doc.at_css("identifier").content).to eq(doi.doi)
    end

    it "valid model" do
      expect(subject.valid?).to be true
    end

    it "creates namespace" do
      expect(subject.namespace).to eq("http://datacite.org/schema/kernel-3")
    end

    it "creates metadata_version" do
      expect(subject.metadata_version).to eq(1)
    end

    it "creates doi association" do
      expect(subject.doi.doi).to eq(doi.doi)
    end
  end

  context "parses bibtex" do
    let(:provider)  { create(:provider, symbol: "ADMIN") }
    let(:client)  { create(:client, provider: provider) }
    let(:doi) { create(:doi, doi: "10.7554/elife.01567", client: client) }
    let(:xml) { ::Base64.strict_encode64(file_fixture('crossref.bib').read) }

    subject { Metadata.create(xml: xml, doi: doi) }

    it "creates xml" do
      doc = Nokogiri::XML(subject.xml, nil, 'UTF-8', &:noblanks)
      expect(doc.at_css("identifier").content).to eq(doi.doi.downcase)
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

  context "parses ris" do
    let(:provider)  { create(:provider, symbol: "ADMIN") }
    let(:client)  { create(:client, provider: provider) }
    let(:doi) { create(:doi, doi: "10.7554/elife.01567", client: client) }
    let(:xml) { ::Base64.strict_encode64(file_fixture('crossref.ris').read) }

    subject { Metadata.create(xml: xml, doi: doi) }

    it "creates xml" do
      doc = Nokogiri::XML(subject.xml, nil, 'UTF-8', &:noblanks)
      expect(doc.at_css("identifier").content).to eq(doi.doi.downcase)
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

  context "parses citeproc" do
    let(:provider)  { create(:provider, symbol: "ADMIN") }
    let(:client)  { create(:client, provider: provider) }
    let(:doi) { create(:doi, doi: "10.5438/4k3m-nyvg", client: client) }
    let(:xml) { ::Base64.strict_encode64(file_fixture('citeproc.json').read) }

    subject { Metadata.create(xml: xml, doi: doi) }

    it "creates xml" do
      doc = Nokogiri::XML(subject.xml, nil, 'UTF-8', &:noblanks)
      expect(doc.at_css("identifier").content).to eq(doi.doi.downcase)
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

  context "parses codemeta" do
    let(:provider)  { create(:provider, symbol: "ADMIN") }
    let(:client)  { create(:client, provider: provider) }
    let(:doi) { create(:doi, doi: "10.5063/f1m61h5x", client: client) }
    let(:xml) { ::Base64.strict_encode64(file_fixture('codemeta.json').read) }

    subject { Metadata.create(xml: xml, doi: doi) }

    it "creates xml" do
      doc = Nokogiri::XML(subject.xml, nil, 'UTF-8', &:noblanks)
      expect(doc.at_css("identifier").content).to eq(doi.doi.downcase)
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

  context "parses crosscite" do
    let(:provider)  { create(:provider, symbol: "ADMIN") }
    let(:client)  { create(:client, provider: provider) }
    let(:doi) { create(:doi, doi: "10.5281/zenodo.48440", client: client) }
    let(:xml) { ::Base64.strict_encode64(file_fixture('crosscite.json').read) }

    subject { Metadata.create(xml: xml, doi: doi) }

    it "creates xml" do
      doc = Nokogiri::XML(subject.xml, nil, 'UTF-8', &:noblanks)
      expect(doc.at_css("identifier").content).to eq(doi.doi.downcase)
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

  context "parses schema.org" do
    let(:provider)  { create(:provider, symbol: "ADMIN") }
    let(:client)  { create(:client, provider: provider) }
    let(:doi) { create(:doi, doi: "10.5438/4k3m-nyvg", client: client) }
    let(:xml) { ::Base64.strict_encode64(file_fixture('schema_org.json').read) }

    subject { Metadata.create(xml: xml, doi: doi) }

    it "creates xml" do
      doc = Nokogiri::XML(subject.xml, nil, 'UTF-8', &:noblanks)
      expect(doc.at_css("identifier").content).to eq(doi.doi.downcase)
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
end
