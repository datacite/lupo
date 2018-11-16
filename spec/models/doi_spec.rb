require 'rails_helper'

describe Doi, type: :model, vcr: true do
  describe "validations" do
    it { should validate_presence_of(:doi) }
  end

  describe "validate doi" do
    it "using base32 crockford checksum =" do
      subject = build(:doi, doi: "10.18730/nvb5=")
      expect(subject).to be_valid
    end

    it "using base32 crockford checksum $" do
      subject = build(:doi, doi: "10.18730/nvb4$")
      expect(subject).to be_valid
    end

    it "using base32 crockford checksum ~" do
      subject = build(:doi, doi: "10.18730/nvb3~")
      expect(subject).to be_valid
    end

    it "using base32 crockford checksum *" do
      subject = build(:doi, doi: "10.18730/nvb2*")
      expect(subject).to be_valid
    end
  end

  describe "state" do
    subject { create(:doi) }

    describe "draft" do
      it "default" do
        expect(subject).to have_state(:draft)
      end
    end

    describe "registered" do
      it "can register" do
        subject.register
        expect(subject).to have_state(:registered)
      end

      it "can't register with test prefix" do
        subject = create(:doi, doi: "10.5072/x")
        subject.register
        expect(subject).to have_state(:draft)
      end
    end

    describe "findable" do
      it "can publish" do
        subject.publish
        expect(subject).to have_state(:findable)
      end

      it "can't register with test prefix" do
        subject = create(:doi, doi: "10.5072/x")
        subject.publish
        expect(subject).to have_state(:draft)
      end
    end

    describe "flagged" do
      it "can flag" do
        subject.register
        subject.flag
        expect(subject).to have_state(:flagged)
      end

      it "can't flag if draft" do
        subject.flag
        expect(subject).to have_state(:draft)
      end
    end

    describe "broken" do
      it "can link_check" do
        subject.register
        subject.link_check
        expect(subject).to have_state(:broken)
      end

      it "can't link_check if draft" do
        subject.link_check
        expect(subject).to have_state(:draft)
      end
    end
  end

  describe "url" do
    it "can handle long urls" do
      url = "http://core.tdar.org/document/365177/new-york-african-burial-ground-skeletal-biology-final-report-volume-1-chapter-5-origins-of-the-new-york-african-burial-ground-population-biological-evidence-of-geographical-and-macroethnic-affiliations-using-craniometrics-dental-morphology-and-preliminary-genetic-analysis"
      subject = create(:doi, url: url)
      expect(subject.url).to eq(url)
    end

    it "can handle ftp urls" do
      url = "ftp://ftp.library.noaa.gov/noaa_documents.lib/NESDIS/GSICS_quarterly/v1_no2_2007.pdf"
      subject = create(:doi, url: url)
      expect(subject.url).to eq(url)
    end
  end

  describe "update_url" do
    let(:token) { User.generate_token(role_id: "client_admin") }
    let(:current_user) { User.new(token) }

    context "draft doi" do
      let(:provider)  { create(:provider, symbol: "ADMIN") }
      let(:client)  { create(:client, provider: provider) }
      let(:url) { "https://www.example.org" }
      subject { build(:doi, client: client, current_user: current_user) }

      it "don't update state change" do
        expect { subject.save }.not_to have_enqueued_job(HandleJob)
        expect(subject).to have_state(:draft)
      end

      it "don't update url change" do
        subject.url = url
        expect { subject.save }.not_to have_enqueued_job(HandleJob)
      end
    end

    context "registered doi" do
      let(:provider)  { create(:provider, symbol: "ADMIN") }
      let(:client)  { create(:client, provider: provider) }
      let(:url) { "https://www.example.org" }
      subject { build(:doi, client: client, current_user: current_user) }

      it "update state change" do
        subject.register
        expect { subject.save }.to have_enqueued_job(HandleJob).on_queue("test_lupo").with { |doi_id|
          expect(doi_id).to eq(subject.doi)
        }
        expect(subject).to have_state(:registered)
      end

      it "update url change" do
        subject.register
        subject.url = url
        expect { subject.save }.to have_enqueued_job(HandleJob).on_queue("test_lupo").with { |doi_id|
          expect(doi_id).to eq(subject.doi)
        }
      end
    end

    context "findable doi" do
      let(:provider)  { create(:provider, symbol: "ADMIN") }
      let(:client)  { create(:client, provider: provider) }
      let(:url) { "https://www.example.org" }
      subject { build(:doi, client: client, current_user: current_user) }

      it "update state change" do
        subject.publish
        expect { subject.save }.to have_enqueued_job(HandleJob).on_queue("test_lupo").with { |doi_id|
          expect(doi_id).to eq(subject.doi)
        }
        expect(subject).to have_state(:findable)
      end

      it "update url change" do
        subject.publish
        subject.url = url
        expect { subject.save }.to have_enqueued_job(HandleJob).on_queue("test_lupo").with { |doi_id|
          expect(doi_id).to eq(subject.doi)
        }
      end
    end

    context "provider ethz" do
      let(:provider)  { create(:provider, symbol: "ETHZ") }
      let(:client)  { create(:client, provider: provider) }
      let(:url) { "https://www.example.org" }
      subject { build(:doi, client: client, current_user: current_user) }

      it "don't update state change" do
        subject.publish
        expect { subject.save }.not_to have_enqueued_job(HandleJob)
        expect(subject).to have_state(:findable)
      end

      it "don't update url change" do
        subject.publish
        subject.url = url
        expect { subject.save }.not_to have_enqueued_job(HandleJob)
      end
    end

    context "provider europ" do
      let(:provider)  { create(:provider, symbol: "EUROP") }
      let(:client)  { create(:client, provider: provider) }
      let(:url) { "https://www.example.org" }
      subject { build(:doi, client: client, current_user: current_user) }

      it "don't update state change" do
        subject.publish
        expect { subject.save }.not_to have_enqueued_job(HandleJob)
        expect(subject).to have_state(:findable)
      end

      it "don't update url change" do
        subject.publish
        subject.url = url
        expect { subject.save }.not_to have_enqueued_job(HandleJob)
      end
    end

    context "no current_user" do
      let(:provider)  { create(:provider, symbol: "ADMIN") }
      let(:client)  { create(:client, provider: provider) }
      let(:url) { "https://www.example.org" }
      subject { build(:doi, client: client, current_user: nil) }

      it "don't update state change" do
        subject.publish
        expect { subject.save }.not_to have_enqueued_job(HandleJob)
        expect(subject).to have_state(:findable)
      end

      it "don't update url change" do
        subject.publish
        subject.url = url
        expect { subject.save }.not_to have_enqueued_job(HandleJob)
      end
    end

    context "no url" do
      let(:provider)  { create(:provider, symbol: "ADMIN") }
      let(:client)  { create(:client, provider: provider) }
      let(:url) { "https://www.example.org" }
      subject { build(:doi, client: client, url: nil, current_user: current_user) }

      # it "don't update state change" do
      #   subject.publish
      #   expect { subject.save }.not_to have_enqueued_job(HandleJob)
      #   expect(subject).to have_state(:findable)
      # end

      it "update url change" do
        subject.publish
        subject.url = url
        expect { subject.save }.to have_enqueued_job(HandleJob)
      end
    end
  end

  describe "metadata" do
    let(:xml) { "PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiIHN0YW5kYWxvbmU9InllcyI/PjxyZXNvdXJjZSB4c2k6c2NoZW1hTG9jYXRpb249Imh0dHA6Ly9kYXRhY2l0ZS5vcmcvc2NoZW1hL2tlcm5lbC0zIGh0dHA6Ly9zY2hlbWEuZGF0YWNpdGUub3JnL21ldGEva2VybmVsLTMvbWV0YWRhdGEueHNkIiB4bWxucz0iaHR0cDovL2RhdGFjaXRlLm9yZy9zY2hlbWEva2VybmVsLTMiIHhtbG5zOnhzaT0iaHR0cDovL3d3dy53My5vcmcvMjAwMS9YTUxTY2hlbWEtaW5zdGFuY2UiPjxpZGVudGlmaWVyIGlkZW50aWZpZXJUeXBlPSJET0kiPjEwLjUyNTYvZjEwMDByZXNlYXJjaC44NTcwLnI2NDIwPC9pZGVudGlmaWVyPjxjcmVhdG9ycz48Y3JlYXRvcj48Y3JlYXRvck5hbWU+ZCBzPC9jcmVhdG9yTmFtZT48L2NyZWF0b3I+PC9jcmVhdG9ycz48dGl0bGVzPjx0aXRsZT5SZWZlcmVlIHJlcG9ydC4gRm9yOiBSRVNFQVJDSC0zNDgyIFt2ZXJzaW9uIDU7IHJlZmVyZWVzOiAxIGFwcHJvdmVkLCAxIGFwcHJvdmVkIHdpdGggcmVzZXJ2YXRpb25zXTwvdGl0bGU+PC90aXRsZXM+PHB1Ymxpc2hlcj5GMTAwMCBSZXNlYXJjaCBMaW1pdGVkPC9wdWJsaXNoZXI+PHB1YmxpY2F0aW9uWWVhcj4yMDE3PC9wdWJsaWNhdGlvblllYXI+PHJlc291cmNlVHlwZSByZXNvdXJjZVR5cGVHZW5lcmFsPSJUZXh0Ii8+PC9yZXNvdXJjZT4=" }

    subject  { create(:doi, xml: xml) }

    it "title" do
      expect(subject.titles).to eq([{"title"=>"Referee report. For: RESEARCH-3482 [version 5; referees: 1 approved, 1 approved with reservations]"}])
    end

    it "creator" do
      expect(subject.creator).to eq([{"name"=>"D S"}])
    end

    it "dates" do
      expect(subject.get_date(subject.dates, "Issued")).to eq("2017")
    end

    it "publication_year" do
      expect(subject.publication_year).to eq(2017)
    end

    it "schema_version" do
      expect(subject.schema_version).to eq("http://datacite.org/schema/kernel-3")
    end

    it "metadata" do
      doc = Nokogiri::XML(subject.metadata.first.xml, nil, 'UTF-8', &:noblanks)
      expect(doc.at_css("identifier").content).to eq(subject.doi)
    end

    it "namespace" do
      expect(subject.metadata.first.namespace).to eq("http://datacite.org/schema/kernel-3")
    end
  end

  describe "change metadata" do
    let(:xml) { "PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiIHN0YW5kYWxvbmU9InllcyI/PjxyZXNvdXJjZSB4c2k6c2NoZW1hTG9jYXRpb249Imh0dHA6Ly9kYXRhY2l0ZS5vcmcvc2NoZW1hL2tlcm5lbC0zIGh0dHA6Ly9zY2hlbWEuZGF0YWNpdGUub3JnL21ldGEva2VybmVsLTMvbWV0YWRhdGEueHNkIiB4bWxucz0iaHR0cDovL2RhdGFjaXRlLm9yZy9zY2hlbWEva2VybmVsLTMiIHhtbG5zOnhzaT0iaHR0cDovL3d3dy53My5vcmcvMjAwMS9YTUxTY2hlbWEtaW5zdGFuY2UiPjxpZGVudGlmaWVyIGlkZW50aWZpZXJUeXBlPSJET0kiPjEwLjUyNTYvZjEwMDByZXNlYXJjaC44NTcwLnI2NDIwPC9pZGVudGlmaWVyPjxjcmVhdG9ycz48Y3JlYXRvcj48Y3JlYXRvck5hbWU+ZCBzPC9jcmVhdG9yTmFtZT48L2NyZWF0b3I+PC9jcmVhdG9ycz48dGl0bGVzPjx0aXRsZT5SZWZlcmVlIHJlcG9ydC4gRm9yOiBSRVNFQVJDSC0zNDgyIFt2ZXJzaW9uIDU7IHJlZmVyZWVzOiAxIGFwcHJvdmVkLCAxIGFwcHJvdmVkIHdpdGggcmVzZXJ2YXRpb25zXTwvdGl0bGU+PC90aXRsZXM+PHB1Ymxpc2hlcj5GMTAwMCBSZXNlYXJjaCBMaW1pdGVkPC9wdWJsaXNoZXI+PHB1YmxpY2F0aW9uWWVhcj4yMDE3PC9wdWJsaWNhdGlvblllYXI+PHJlc291cmNlVHlwZSByZXNvdXJjZVR5cGVHZW5lcmFsPSJUZXh0Ii8+PC9yZXNvdXJjZT4=" }

    subject  { build(:doi, xml: xml) }

    it "titles" do
      titles = [{ "title" => "Triose Phosphate Isomerase Deficiency Is Caused by Altered Dimerization–Not Catalytic Inactivity–of the Mutant Enzymes" }]
      subject.titles = titles
      subject.save
      
      expect(subject.titles).to eq(titles)

      xml = Maremma.from_xml(subject.xml).fetch("resource", {})
      expect(xml.dig("titles", "title")).to eq(titles)
    end

    it "creator" do
      creator = [{ "name"=>"Ollomi, Benjamin" }, { "name"=>"Duran, Patrick" }]
      subject.creator = creator
      subject.save

      expect(subject.creator).to eq(creator)

      xml = Maremma.from_xml(subject.xml).fetch("resource", {})
      expect(xml.dig("creators", "creator")).to eq([{"creatorName"=>"Ollomi, Benjamin"}, {"creatorName"=>"Duran, Patrick"}])
    end

    it "publisher" do
      publisher = "Zenodo"
      subject.publisher = publisher
      subject.save

      expect(subject.publisher).to eq(publisher)

      xml = Maremma.from_xml(subject.xml).fetch("resource", {})
      expect(xml.dig("publisher")).to eq(publisher)
    end

    it "date_published" do
      subject.set_date(subject.dates, "2011-05-26", "Issued")
      subject.publication_year = "2011"
      subject.save

      expect(subject.dates).to eq([{"date"=>"2011-05-26", "dateType"=>"Issued"}])

      xml = Maremma.from_xml(subject.xml).fetch("resource", {})
      expect(xml.dig("dates", "date")).to eq("dateType"=>"Issued", "__content__"=>"2011-05-26")
      expect(xml.dig("publicationYear")).to eq("2011")
    end

    it "resource_type" do
      resource_type = "BlogPosting"
      subject.types["resource_type"] = resource_type
      subject.save

      expect(subject.types["resource_type"]).to eq(resource_type)

      xml = Maremma.from_xml(subject.xml).fetch("resource", {})
      expect(xml.dig("resourceType")).to eq("resourceTypeGeneral"=>"Text", "__content__"=>"BlogPosting")
    end

    it "resource_type_general" do
      resource_type_general = "Software"
      subject.types["resource_type_general"] = resource_type_general
      subject.save

      expect(subject.types["resource_type_general"]).to eq(resource_type_general)

      xml = Maremma.from_xml(subject.xml).fetch("resource", {})
      expect(xml.dig("resourceType")).to eq("resourceTypeGeneral"=>resource_type_general, "__content__"=>"ScholarlyArticle")
    end

    it "description" do
      descriptions = [{ "description" => "Eating your own dog food is a slang term to describe that an organization should itself use the products and services it provides. For DataCite this means that we should use DOIs with appropriate metadata and strategies for long-term preservation for..." }]
      subject.descriptions = descriptions
      subject.save
      
      expect(subject.descriptions).to eq(descriptions)

      xml = Maremma.from_xml(subject.xml).fetch("resource", {})
      expect(xml.dig("descriptions", "description")).to eq("__content__" => "Eating your own dog food is a slang term to describe that an organization should itself use the products and services it provides. For DataCite this means that we should use DOIs with appropriate metadata and strategies for long-term preservation for...", "descriptionType" => "Abstract")
    end

    it "schema_version" do
      titles = [{ "title" => "Triose Phosphate Isomerase Deficiency Is Caused by Altered Dimerization–Not Catalytic Inactivity–of the Mutant Enzymes" }]
      subject.titles = titles
      subject.save

      xml = Maremma.from_xml(subject.xml).fetch("resource", {})
      expect(xml.dig("titles", "title")).to eq(titles)

      expect(subject.schema_version).to eq("http://datacite.org/schema/kernel-4")
      expect(xml.dig("xmlns")).to eq("http://datacite.org/schema/kernel-4")
      #expect(subject.metadata.first.namespace).to eq("http://datacite.org/schema/kernel-4")
    end
  end

  describe "to_jsonapi" do
    let(:provider)  { create(:provider, symbol: "ADMIN") }
    let(:client)  { create(:client, provider: provider) }
    let(:doi) { create(:doi, client: client) }

    it "works" do
      params = doi.to_jsonapi
      expect(params.dig("id")).to eq(doi.doi)
      expect(params.dig("attributes","state")).to eq("draft")
      expect(params.dig("attributes","created")).to eq(doi.created)
      expect(params.dig("attributes","updated")).to eq(doi.updated)
    end
  end

  context "parses Crossref xml" do
    let(:xml) { Base64.strict_encode64(file_fixture('crossref.xml').read) }

    subject { create(:doi, xml: xml, event: "publish") }

    it "creates xml" do
      doc = Nokogiri::XML(subject.xml, nil, 'UTF-8', &:noblanks)
      expect(doc.at_css("identifier").content).to eq(subject.doi)
    end

    it "valid model" do
      expect(subject.valid?).to be true
    end

    it "validates against schema" do
      expect(subject.validation_errors).to be_empty
    end

    it "title" do
      expect(subject.titles).to eq([{"title"=>"Triose Phosphate Isomerase Deficiency Is Caused by Altered Dimerization–Not Catalytic Inactivity–of the Mutant Enzymes"}])
    end

    it "date_published" do
      expect(subject.get_date(subject.dates, "Issued")).to eq("2006-12-20")
    end

    it "publication_year" do
      expect(subject.publication_year).to eq(2006)
    end

    it "creator" do
      expect(subject.creator.length).to eq(5)
      expect(subject.creator.first).to eq("type"=>"Person", "name"=>"Markus Ralser", "givenName"=>"Markus", "familyName"=>"Ralser")
    end

    it "schema_version" do
      expect(subject.schema_version).to eq("http://datacite.org/schema/kernel-4")
    end

    it "metadata" do
      doc = Nokogiri::XML(subject.metadata.first.xml, nil, 'UTF-8', &:noblanks)
      expect(doc.at_css("identifier").content).to eq(subject.doi)
    end

    it "namespace" do
      expect(subject.metadata.first.namespace).to eq("http://datacite.org/schema/kernel-4")
    end
  end

  context "parses namespaced xml" do
    let(:xml) { Base64.strict_encode64(file_fixture('ns0.xml').read) }

    subject { create(:doi, doi: "10.4231/D38G8FK8B", xml: xml, event: "publish") }

    it "creates xml" do
      doc = Nokogiri::XML(subject.xml, nil, 'UTF-8', &:noblanks)
      doc.remove_namespaces!
      expect(doc.at_css("identifier").content).to eq(subject.doi)
    end

    it "valid model" do
      expect(subject.valid?).to be true
    end

    it "validates against schema" do
      expect(subject.validation_errors).to be_empty
    end

    it "title" do
      expect(subject.titles).to eq([{"title"=>"LAMMPS Data-File Generator"}])
    end

    it "date_published" do
      expect(subject.get_date(subject.dates, "Issued")).to eq("2018")
    end

    it "publication_year" do
      expect(subject.publication_year).to eq(2018)
    end

    it "creator" do
      expect(subject.creator.length).to eq(5)
      expect(subject.creator.first).to eq("type"=>"Person", "name"=>"Carlos PatiÃ±O", "givenName"=>"Carlos", "familyName"=>"PatiÃ±O")
    end

    it "schema_version" do
      expect(subject.schema_version).to eq("http://datacite.org/schema/kernel-2.2")
    end

    it "metadata" do
      doc = Nokogiri::XML(subject.metadata.first.xml, nil, 'UTF-8', &:noblanks)
      doc.remove_namespaces!
      expect(doc.at_css("identifier").content).to eq(subject.doi)
    end

    it "namespace" do
      expect(subject.metadata.first.namespace).to eq("http://datacite.org/schema/kernel-2.2")
    end
  end

  context "parses schema" do
    let(:xml) { Base64.strict_encode64(file_fixture('datacite.xml').read) }

    subject { create(:doi, xml: xml, event: "publish") }

    it "creates xml" do
      doc = Nokogiri::XML(subject.xml, nil, 'UTF-8', &:noblanks)
      expect(doc.at_css("identifier").content).to eq(subject.doi)
    end

    it "valid model" do
      expect(subject.valid?).to be true
    end

    it "validates against schema" do
      expect(subject.validation_errors).to be_empty
    end

    it "title" do
      expect(subject.titles).to eq([{"title"=>"Eating your own Dog Food"}])
    end

    it "creator" do
      expect(subject.creator).to eq([{"type"=>"Person", "id"=>"https://orcid.org/0000-0003-1419-2405", "name"=>"Fenner, Martin", "givenName"=>"Martin", "familyName"=>"Fenner"}])
    end

    it "dates" do
      expect(subject.get_date(subject.dates, "Issued")).to eq("2016-12-20")
    end

    it "publication_year" do
      expect(subject.publication_year).to eq(2016)
    end

    it "creates schema_version" do
      expect(subject.schema_version).to eq("http://datacite.org/schema/kernel-4")
    end

    it "metadata" do
      doc = Nokogiri::XML(subject.metadata.first.xml, nil, 'UTF-8', &:noblanks)
      expect(doc.at_css("identifier").content).to eq(subject.doi)
    end

    it "namespace" do
      expect(subject.metadata.first.namespace).to eq("http://datacite.org/schema/kernel-4")
    end
  end

  context "parses schema 3" do
    let(:xml) { Base64.strict_encode64(file_fixture('datacite_schema_3.xml').read) }

    subject { create(:doi, xml: xml, event: "publish") }

    it "creates xml" do
      doc = Nokogiri::XML(subject.xml, nil, 'UTF-8', &:noblanks)
      expect(doc.at_css("identifier").content).to eq(subject.doi)
    end

    it "valid model" do
      expect(subject.valid?).to be true
    end

    it "title" do
      expect(subject.titles).to eq([{"title"=>"Data from: A new malaria agent in African hominids."}])
    end

    it "creator" do
      expect(subject.creator.length).to eq(8)
      expect(subject.creator.first).to eq("type"=>"Person", "name"=>"Benjamin Ollomo", "givenName"=>"Benjamin", "familyName"=>"Ollomo")
    end

    it "dates" do
      expect(subject.get_date(subject.dates, "Issued")).to eq("2011")
    end

    it "publication_year" do
      expect(subject.publication_year).to eq(2011)
    end

    it "creates schema_version" do
      expect(subject.schema_version).to eq("http://datacite.org/schema/kernel-3")
    end

    it "metadata" do
      doc = Nokogiri::XML(subject.metadata.first.xml, nil, 'UTF-8', &:noblanks)
      expect(doc.at_css("identifier").content).to eq(subject.doi)
    end

    it "namespace" do
      expect(subject.metadata.first.namespace).to eq("http://datacite.org/schema/kernel-3")
    end
  end

  context "parses schema 2.2" do
    let(:xml) { Base64.strict_encode64(file_fixture('datacite_schema_2.2.xml').read) }

    subject { create(:doi, xml: xml, event: "publish") }

    it "creates xml" do
      doc = Nokogiri::XML(subject.xml, nil, 'UTF-8', &:noblanks)
      expect(doc.at_css("identifier").content).to eq(subject.doi)
    end

    it "valid model" do
      expect(subject.valid?).to be true
    end

    it "title" do
      expect(subject.titles).to eq([{"title"=>"Właściwości rzutowań podprzestrzeniowych"}, {"title"=>"Translation of Polish titles", "titleType"=>"TranslatedTitle"}])
    end

    it "creator" do
      expect(subject.creator.length).to eq(2)
      expect(subject.creator.first).to eq("type"=>"Person", "name"=>"John Smith", "givenName"=>"John", "familyName"=>"Smith")
    end

    it "dates" do
      expect(subject.get_date(subject.dates, "Issued")).to eq("2010")
    end

    it "publication_year" do
      expect(subject.publication_year).to eq(2010)
    end

    it "creates schema_version" do
      expect(subject.schema_version).to eq("http://datacite.org/schema/kernel-2.2")
    end

    it "metadata" do
      doc = Nokogiri::XML(subject.metadata.first.xml, nil, 'UTF-8', &:noblanks)
      expect(doc.at_css("identifier").content).to eq(subject.doi)
    end

    it "namespace" do
      expect(subject.metadata.first.namespace).to eq("http://datacite.org/schema/kernel-2.2")
    end
  end

  context "parses bibtex" do
    let(:xml) { Base64.strict_encode64(file_fixture('crossref.bib').read) }

    subject { create(:doi, xml: xml, event: "publish") }

    it "creates xml" do
      doc = Nokogiri::XML(subject.xml, nil, 'UTF-8', &:noblanks)
      expect(doc.at_css("identifier").content).to eq(subject.doi)
    end

    it "valid model" do
      expect(subject.valid?).to be true
    end

    it "validates against schema" do
      expect(subject.validation_errors).to be_empty
    end

    it "title" do
      expect(subject.titles).to eq([{"title"=>"Automated quantitative histology reveals vascular morphodynamics during Arabidopsis hypocotyl secondary growth"}])
    end

    it "creator" do
      expect(subject.creator.length).to eq(5)
      expect(subject.creator.first).to eq("type"=>"Person", "name"=>"Martial Sankar", "givenName"=>"Martial", "familyName"=>"Sankar")
    end

    it "creates schema_version" do
      expect(subject.schema_version).to eq("http://datacite.org/schema/kernel-4")
    end

    it "metadata" do
      doc = Nokogiri::XML(subject.metadata.first.xml, nil, 'UTF-8', &:noblanks)
      expect(doc.at_css("identifier").content).to eq(subject.doi)
    end

    it "namespace" do
      expect(subject.metadata.first.namespace).to eq("http://datacite.org/schema/kernel-4")
    end
  end

  context "parses ris" do
    let(:xml) { ::Base64.strict_encode64(file_fixture('crossref.ris').read) }

    subject { create(:doi, xml: xml, event: "publish") }

    it "creates xml" do
      doc = Nokogiri::XML(subject.xml, nil, 'UTF-8', &:noblanks)
      expect(doc.at_css("identifier").content).to eq(subject.doi)
    end

    it "valid model" do
      expect(subject.valid?).to be true
    end

    it "validates against schema" do
      expect(subject.validation_errors).to be_empty
    end

    it "title" do
      expect(subject.titles).to eq([{"title"=>"Automated quantitative histology reveals vascular morphodynamics during Arabidopsis hypocotyl secondary growth"}])
    end

    it "creator" do
      expect(subject.creator.length).to eq(5)
      expect(subject.creator.first).to eq("type"=>"Person", "name"=>"Martial Sankar", "givenName"=>"Martial", "familyName"=>"Sankar")
    end

    it "creates schema_version" do
      expect(subject.schema_version).to eq("http://datacite.org/schema/kernel-4")
    end

    it "metadata" do
      doc = Nokogiri::XML(subject.metadata.first.xml, nil, 'UTF-8', &:noblanks)
      expect(doc.at_css("identifier").content).to eq(subject.doi)
    end

    it "namespace" do
      expect(subject.metadata.first.namespace).to eq("http://datacite.org/schema/kernel-4")
    end
  end

  context "parses citeproc" do
    let(:xml) { ::Base64.strict_encode64(file_fixture('citeproc.json').read) }

    subject { create(:doi, xml: xml, event: "publish") }

    it "creates xml" do
      doc = Nokogiri::XML(subject.xml, nil, 'UTF-8', &:noblanks)
      expect(doc.at_css("identifier").content).to eq(subject.doi)
    end

    it "valid model" do
      expect(subject.valid?).to be true
    end

    it "validates against schema" do
      expect(subject.validation_errors).to be_empty
    end

    it "title" do
      expect(subject.titles).to eq([{"title"=>"Eating your own Dog Food"}])
    end

    it "creator" do
      expect(subject.creator).to eq([{"type"=>"Person", "name"=>"Martin Fenner", "givenName"=>"Martin", "familyName"=>"Fenner"}])
    end

    it "creates schema_version" do
      expect(subject.schema_version).to eq("http://datacite.org/schema/kernel-4")
    end

    it "metadata" do
      doc = Nokogiri::XML(subject.metadata.first.xml, nil, 'UTF-8', &:noblanks)
      expect(doc.at_css("identifier").content).to eq(subject.doi)
    end

    it "namespace" do
      expect(subject.metadata.first.namespace).to eq("http://datacite.org/schema/kernel-4")
    end
  end

  context "parses codemeta" do
    let(:xml) { ::Base64.strict_encode64(file_fixture('codemeta.json').read) }

    subject { create(:doi, xml: xml, event: "publish") }

    it "creates xml" do
      doc = Nokogiri::XML(subject.xml, nil, 'UTF-8', &:noblanks)
      expect(doc.at_css("identifier").content).to eq(subject.doi)
    end

    it "valid model" do
      expect(subject.valid?).to be true
    end

    it "validates against schema" do
      expect(subject.validation_errors).to be_empty
    end

    it "title" do
      expect(subject.titles).to eq([{"title"=>"R Interface to the DataONE REST API"}])
    end

    it "creator" do
      expect(subject.creator.length).to eq(3)
      expect(subject.creator.first).to eq("type"=>"Person", "id"=>"http://orcid.org/0000-0003-0077-4738", "name"=>"Matt Jones", "givenName"=>"Matt", "familyName"=>"Jones")
    end

    it "creates schema_version" do
      expect(subject.schema_version).to eq("http://datacite.org/schema/kernel-4")
    end

    it "metadata" do
      doc = Nokogiri::XML(subject.metadata.first.xml, nil, 'UTF-8', &:noblanks)
      expect(doc.at_css("identifier").content).to eq(subject.doi)
    end

    it "namespace" do
      expect(subject.metadata.first.namespace).to eq("http://datacite.org/schema/kernel-4")
    end
  end

  context "parses crosscite" do
    let(:xml) { ::Base64.strict_encode64(file_fixture('crosscite.json').read) }

    subject { create(:doi, xml: xml, event: "publish") }

    it "creates xml" do
      doc = Nokogiri::XML(subject.xml, nil, 'UTF-8', &:noblanks)
      expect(doc.at_css("identifier").content).to eq(subject.doi)
    end

    it "valid model" do
      expect(subject.valid?).to be true
    end

    it "validates against schema" do
      expect(subject.validation_errors).to be_empty
    end

    it "title" do
      expect(subject.titles).to eq([{"title"=>"Analysis Tools for Crossover Experiment of UI using Choice Architecture"}])
    end

    it "creator" do
      expect(subject.creator).to eq([{"familyName"=>"Garza", "givenName"=>"Kristian", "name"=>"Kristian Garza", "type"=>"Person"}])
    end

    it "creates schema_version" do
      expect(subject.schema_version).to eq("http://datacite.org/schema/kernel-4")
    end

    it "metadata" do
      doc = Nokogiri::XML(subject.metadata.first.xml, nil, 'UTF-8', &:noblanks)
      expect(doc.at_css("identifier").content).to eq(subject.doi)
    end

    it "namespace" do
      expect(subject.metadata.first.namespace).to eq("http://datacite.org/schema/kernel-4")
    end
  end

  context "parses schema.org" do
    let(:xml) { ::Base64.strict_encode64(file_fixture('schema_org.json').read) }

    subject { create(:doi, xml: xml, event: "publish") }

    it "creates xml" do
      doc = Nokogiri::XML(subject.xml, nil, 'UTF-8', &:noblanks)
      expect(doc.at_css("identifier").content).to eq(subject.doi)
    end

    it "valid model" do
      expect(subject.valid?).to be true
    end

    it "validates against schema" do
      expect(subject.validation_errors).to be_empty
    end

    it "title" do
      expect(subject.titles).to eq([{"title"=>"Eating your own Dog Food"}])
    end

    it "creator" do
      expect(subject.creator).to eq([{"familyName"=>"Fenner", "givenName"=>"Martin", "id"=>"http://orcid.org/0000-0003-1419-2405", "name"=>"Martin Fenner", "type"=>"Person"}])
    end

    it "creates schema_version" do
      expect(subject.schema_version).to eq("http://datacite.org/schema/kernel-4")
    end

    it "metadata" do
      doc = Nokogiri::XML(subject.metadata.first.xml, nil, 'UTF-8', &:noblanks)
      expect(doc.at_css("identifier").content).to eq(subject.doi)
    end

    it "namespace" do
      expect(subject.metadata.first.namespace).to eq("http://datacite.org/schema/kernel-4")
    end
  end

  context "parses schema.org topmed" do
    let(:xml) { ::Base64.strict_encode64(file_fixture('schema_org_topmed.json').read) }

    subject { create(:doi, xml: xml, event: "publish") }

    it "creates xml" do
      doc = Nokogiri::XML(subject.xml, nil, 'UTF-8', &:noblanks)
      expect(doc.at_css("identifier").content).to eq(subject.doi)
      expect(doc.at_css("relatedIdentifiers").content).to eq("10.23725/2g4s-qv04")
    end

    it "valid model" do
      expect(subject.valid?).to be true
    end

    it "validates against schema" do
      expect(subject.validation_errors).to be_empty
    end

    it "title" do
      expect(subject.titles).to eq([{"title"=>"NWD165827.recab.cram"}])
    end

    it "creator" do
      expect(subject.creator).to eq([{"name"=>"TOPMed IRC", "type"=>"Organization"}])
    end

    it "content_url" do
      expect(subject.content_url).to eq(["s3://cgp-commons-public/topmed_open_access/197bc047-e917-55ed-852d-d563cdbc50e4/NWD165827.recab.cram", "gs://topmed-irc-share/public/NWD165827.recab.cram"])
    end

    it "related_identifiers" do
      expect(subject.related_identifiers).to eq([{"relatedIdentifier"=>"10.23725/2g4s-qv04", "relatedIdentifierType"=>"DOI", "relationType"=>"References", "resourceTypeGeneral"=>"Dataset"}])
    end

    it "funding_references" do
      expect(subject.funding_references).to eq([{"funderIdentifier"=>"https://doi.org/10.13039/100000050", "funderIdentifierType"=>"Crossref Funder ID", "funderName"=>"National Heart, Lung, and Blood Institute (NHLBI)"}])
    end

    it "alternate_identifier" do
      expect(subject.alternate_identifiers).to eq([{"alternateIdentifier"=>"3b33f6b9338fccab0901b7d317577ea3",
         "alternateIdentifierType"=>"md5"},
        {"alternateIdentifier"=>"ark:/99999/fk41CrU4eszeLUDe",
         "alternateIdentifierType"=>"minid"},
        {"alternateIdentifier"=>"dg.4503/c3d66dc9-58da-411c-83c4-dd656aa3c4b7",
         "alternateIdentifierType"=>"dataguid"}])
    end

    it "creates schema_version" do
      expect(subject.schema_version).to eq("http://datacite.org/schema/kernel-4")
    end

    it "metadata" do
      doc = Nokogiri::XML(subject.metadata.first.xml, nil, 'UTF-8', &:noblanks)
      expect(doc.at_css("identifier").content).to eq(subject.doi)
    end

    it "namespace" do
      expect(subject.metadata.first.namespace).to eq("http://datacite.org/schema/kernel-4")
    end

    it "media" do
      expect(subject.media.pluck(:url)).to eq(["s3://cgp-commons-public/topmed_open_access/197bc047-e917-55ed-852d-d563cdbc50e4/NWD165827.recab.cram", "gs://topmed-irc-share/public/NWD165827.recab.cram"])
    end
  end

  describe "content negotiation" do
    let(:xml) { Base64.strict_encode64(file_fixture('datacite.xml').read) }

    subject { create(:doi, doi: "10.5438/4k3m-nyvg", xml: xml, event: "publish") }

    it "validates against schema" do
      expect(subject.validation_errors).to be_empty
    end

    it "generates datacite_xml" do
      doc = Nokogiri::XML(subject.xml, nil, 'UTF-8', &:noblanks)
      expect(doc.at_css("identifier").content).to eq(subject.doi)
    end

    it "generates bibtex" do
      bibtex = BibTeX.parse(subject.bibtex).to_a(quotes: '').first
      expect(bibtex[:bibtex_type].to_s).to eq("article")
      expect(bibtex[:title].to_s).to eq("Eating your own Dog Food")
    end

    it "generates ris" do
      ris = subject.ris.split("\r\n")
      expect(ris[0]).to eq("TY  - RPRT")
      expect(ris[1]).to eq("T1  - Eating your own Dog Food")
    end

    it "generates schema_org" do
      json = JSON.parse(subject.schema_org)
      expect(json["@type"]).to eq("ScholarlyArticle")
      expect(json["name"]).to eq("Eating your own Dog Food")
    end

    it "generates datacite_json" do
      json = JSON.parse(subject.datacite_json)
      expect(json["doi"]).to eq("10.5438/4K3M-NYVG")
      expect(json["titles"]).to eq([{"title"=>"Eating your own Dog Food"}])
    end

    it "generates codemeta" do
      json = JSON.parse(subject.codemeta)
      expect(json["@type"]).to eq("ScholarlyArticle")
      expect(json["title"]).to eq("Eating your own Dog Food")
    end

    it "generates jats" do
      jats = Maremma.from_xml(subject.jats).fetch("element_citation", {})
      expect(jats.dig("publication_type")).to eq("journal")
      expect(jats.dig("article_title")).to eq("Eating your own Dog Food")
    end

    it "generates rdf_xml" do
      rdf_xml = Maremma.from_xml(subject.rdf_xml).fetch("RDF", {})
      expect(rdf_xml.dig("ScholarlyArticle", "rdf:about")).to eq(subject.identifier)
    end

    it "generates turtle" do
      ttl = subject.turtle.split("\n")
      expect(ttl[0]).to eq("@prefix schema: <http://schema.org/> .")
      expect(ttl[2]).to eq("<https://handle.test.datacite.org/10.5438/4k3m-nyvg> a schema:ScholarlyArticle;")
    end
  end
end
