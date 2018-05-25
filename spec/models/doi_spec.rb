require 'rails_helper'

describe Doi, type: :model, vcr: true do
  describe "validations" do
    it { should validate_presence_of(:doi) }
  end

  describe "state" do
    subject { create(:doi) }

    describe "start" do
      it "can start" do
        subject.start
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
        subject.start
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
        subject.start
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
        subject.start
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
        subject.start

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
  end

  # describe "update_url" do
  #   context "draft doi" do
  #     let(:provider)  { create(:provider, symbol: "ADMIN") }
  #     let(:client)  { create(:client, provider: provider) }
  #     let(:url) { "https://www.example.org" }
  #     subject { create(:doi, client: client, username: client.symbol.downcase, password: "12345") }

  #     it "don't update state change" do
  #       expect { subject.start }.not_to have_enqueued_job(HandleJob)
  #       expect(subject).to have_state(:draft)
  #     end

  #     it "don't update url change" do
  #       subject.start
  #       expect { subject.url = url }.not_to have_enqueued_job(HandleJob)
  #     end
  #   end

  #   context "registered doi" do
  #     let(:provider)  { create(:provider, symbol: "ADMIN") }
  #     let(:client)  { create(:client, provider: provider) }
  #     let(:url) { "https://www.example.org" }
  #     subject { create(:doi, client: client, username: client.symbol.downcase, password: "12345") }

  #     it "update state change" do
  #       expect { subject.register }.to have_enqueued_job(HandleJob).on_queue("test_lupo").with { |doi|
  #         expect(doi.url).to eq(subject.url)
  #       }
  #       expect(subject).to have_state(:registered)
  #     end

  #     it "update url change" do
  #       subject.register
  #       expect { subject.url = url }.to have_enqueued_job(HandleJob).on_queue("test_lupo").with { |doi|
  #         expect(subject.url).to eq(url)
  #       }
  #     end
  #   end

  #   context "findable doi" do
  #     let(:provider)  { create(:provider, symbol: "ADMIN") }
  #     let(:client)  { create(:client, provider: provider) }
  #     let(:url) { "https://www.example.org" }
  #     subject { create(:doi, client: client, username: client.symbol.downcase, password: "12345") }

  #     it "update state change" do
  #       expect { subject.publish }.to have_enqueued_job(HandleJob).on_queue("test_lupo").with { |doi|
  #         expect(doi.url).to eq(subject.url)
  #       }
  #       expect(subject).to have_state(:findable)
  #     end

  #     it "update url change" do
  #       subject.publish
  #       expect { subject.url = url }.to have_enqueued_job(HandleJob).on_queue("test_lupo").with { |doi|
  #         expect(subject.url).to eq(url)
  #       }
  #     end
  #   end

  #   context "provider ethz" do
  #     let(:provider)  { create(:provider, symbol: "ETHZ") }
  #     let(:client)  { create(:client, provider: provider) }
  #     let(:url) { "https://www.example.org" }
  #     subject { create(:doi, client: client, username: client.symbol.downcase, password: "12345") }

  #     it "don't update state change" do
  #       expect { subject.publish }.not_to have_enqueued_job(HandleJob)
  #       expect(subject).to have_state(:findable)
  #     end

  #     it "don't update url change" do
  #       subject.publish
  #       expect { subject.url = url }.not_to have_enqueued_job(HandleJob)
  #     end
  #   end

  #   context "provider europ" do
  #     let(:provider)  { create(:provider, symbol: "EUROP") }
  #     let(:client)  { create(:client, provider: provider) }
  #     let(:url) { "https://www.example.org" }
  #     subject { create(:doi, client: client, username: client.symbol.downcase, password: "12345") }

  #     it "don't update state change" do
  #       expect { subject.publish }.not_to have_enqueued_job(HandleJob)
  #       expect(subject).to have_state(:findable)
  #     end

  #     it "don't update url change" do
  #       subject.publish
  #       expect { subject.url = url }.not_to have_enqueued_job(HandleJob)
  #     end
  #   end

  #   context "no password" do
  #     let(:provider)  { create(:provider, symbol: "ADMIN") }
  #     let(:client)  { create(:client, provider: provider) }
  #     let(:url) { "https://www.example.org" }
  #     subject { create(:doi, client: client, username: client.symbol.downcase, password: nil) }

  #     it "don't update state change" do
  #       expect { subject.publish }.not_to have_enqueued_job(HandleJob)
  #       expect(subject).to have_state(:findable)
  #     end

  #     it "don't update url change" do
  #       subject.publish
  #       expect { subject.url = url }.not_to have_enqueued_job(HandleJob)
  #     end
  #   end

  #   context "no url" do
  #     let(:provider)  { create(:provider, symbol: "ADMIN") }
  #     let(:client)  { create(:client, provider: provider) }
  #     let(:url) { "https://www.example.org" }
  #     subject { create(:doi, client: client, username: client.symbol.downcase, url: nil, password: "12345") }

  #     it "don't update state change" do
  #       expect { subject.publish }.not_to have_enqueued_job(HandleJob)
  #       expect(subject).to have_state(:findable)
  #     end

  #     it "update url change" do
  #       subject.publish
  #       expect { subject.url = url }.to have_enqueued_job(HandleJob)
  #     end
  #   end
  # end

  describe "metadata" do
    let(:xml) { "PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiIHN0YW5kYWxvbmU9InllcyI/PjxyZXNvdXJjZSB4c2k6c2NoZW1hTG9jYXRpb249Imh0dHA6Ly9kYXRhY2l0ZS5vcmcvc2NoZW1hL2tlcm5lbC0zIGh0dHA6Ly9zY2hlbWEuZGF0YWNpdGUub3JnL21ldGEva2VybmVsLTMvbWV0YWRhdGEueHNkIiB4bWxucz0iaHR0cDovL2RhdGFjaXRlLm9yZy9zY2hlbWEva2VybmVsLTMiIHhtbG5zOnhzaT0iaHR0cDovL3d3dy53My5vcmcvMjAwMS9YTUxTY2hlbWEtaW5zdGFuY2UiPjxpZGVudGlmaWVyIGlkZW50aWZpZXJUeXBlPSJET0kiPjEwLjUyNTYvZjEwMDByZXNlYXJjaC44NTcwLnI2NDIwPC9pZGVudGlmaWVyPjxjcmVhdG9ycz48Y3JlYXRvcj48Y3JlYXRvck5hbWU+ZCBzPC9jcmVhdG9yTmFtZT48L2NyZWF0b3I+PC9jcmVhdG9ycz48dGl0bGVzPjx0aXRsZT5SZWZlcmVlIHJlcG9ydC4gRm9yOiBSRVNFQVJDSC0zNDgyIFt2ZXJzaW9uIDU7IHJlZmVyZWVzOiAxIGFwcHJvdmVkLCAxIGFwcHJvdmVkIHdpdGggcmVzZXJ2YXRpb25zXTwvdGl0bGU+PC90aXRsZXM+PHB1Ymxpc2hlcj5GMTAwMCBSZXNlYXJjaCBMaW1pdGVkPC9wdWJsaXNoZXI+PHB1YmxpY2F0aW9uWWVhcj4yMDE3PC9wdWJsaWNhdGlvblllYXI+PHJlc291cmNlVHlwZSByZXNvdXJjZVR5cGVHZW5lcmFsPSJUZXh0Ii8+PC9yZXNvdXJjZT4=" }

    subject  { create(:doi, xml: xml) }

    it "title" do
      expect(subject.title).to eq("Referee report. For: RESEARCH-3482 [version 5; referees: 1 approved, 1 approved with reservations]")
    end

    it "author" do
      expect(subject.author).to eq("name"=>"D S")
    end

    it "date_published" do
      expect(subject.date_published).to eq("2017")
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

    subject  { create(:doi, xml: xml) }

    it "title" do
      title = "Triose Phosphate Isomerase Deficiency Is Caused by Altered Dimerization–Not Catalytic Inactivity–of the Mutant Enzymes"
      subject.title = title
      subject.save
      
      expect(subject.title).to eq(title)

      xml = Maremma.from_xml(subject.xml).fetch("resource", {})
      expect(xml.dig("titles", "title")).to eq(title)
    end

    it "author" do
      author = [{ "name"=>"Ollomi, Benjamin" }, { "name"=>"Duran, Patrick" }]
      subject.author = author
      subject.save

      expect(subject.author).to eq(author)

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
      date_published = "2011-05-26"
      subject.date_published = date_published
      subject.save

      expect(subject.date_published).to eq(date_published)

      xml = Maremma.from_xml(subject.xml).fetch("resource", {})
      expect(xml.dig("dates", "date")).to eq("dateType"=>"Issued", "__content__"=>date_published)
      expect(xml.dig("publicationYear")).to eq("2011")
    end

    it "additional_type" do
      additional_type = "BlogPosting"
      subject.additional_type = additional_type
      subject.save

      expect(subject.additional_type).to eq(additional_type)

      xml = Maremma.from_xml(subject.xml).fetch("resource", {})
      expect(xml.dig("resourceType")).to eq("resourceTypeGeneral"=>"Text", "__content__"=>"BlogPosting")
    end

    it "resource_type_general" do
      resource_type_general = "Software"
      subject.resource_type_general = resource_type_general
      subject.save

      expect(subject.resource_type_general).to eq(resource_type_general)

      xml = Maremma.from_xml(subject.xml).fetch("resource", {})
      expect(xml.dig("resourceType")).to eq("resourceTypeGeneral"=>resource_type_general, "__content__"=>"ScholarlyArticle")
    end

    it "description" do
      description = "Eating your own dog food is a slang term to describe that an organization should itself use the products and services it provides. For DataCite this means that we should use DOIs with appropriate metadata and strategies for long-term preservation for..."
      subject.description = description
      subject.save
      
      expect(subject.description).to eq(description)

      xml = Maremma.from_xml(subject.xml).fetch("resource", {})
      expect(xml.dig("descriptions", "description")).to eq("__content__" => "Eating your own dog food is a slang term to describe that an organization should itself use the products and services it provides. For DataCite this means that we should use DOIs with appropriate metadata and strategies for long-term preservation for...", "descriptionType" => "Abstract")
    end

    it "schema_version" do
      title = "Triose Phosphate Isomerase Deficiency Is Caused by Altered Dimerization–Not Catalytic Inactivity–of the Mutant Enzymes"
      subject.title = title
      subject.save

      xml = Maremma.from_xml(subject.xml).fetch("resource", {})
      expect(xml.dig("titles", "title")).to eq(title)

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
      expect(params.dig("attributes","url")).to eq(doi.url)
      expect(params.dig("attributes","resource-type-id")).to eq("Text")
      expect(params.dig("attributes","schema-version")).to eq("http://datacite.org/schema/kernel-3")
      expect(params.dig("attributes","is-active")).to be true
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
      expect(subject.title).to eq("Triose Phosphate Isomerase Deficiency Is Caused by Altered Dimerization–Not Catalytic Inactivity–of the Mutant Enzymes")
    end

    it "date_published" do
      expect(subject.date_published).to eq("2006-12-20")
    end

    it "publication_year" do
      expect(subject.publication_year).to eq(2006)
    end

    it "author" do
      expect(subject.author.length).to eq(5)
      expect(subject.author.first).to eq("type"=>"Person", "name"=>"Markus Ralser", "givenName"=>"Markus", "familyName"=>"Ralser")
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
      expect(subject.title).to eq("Eating your own Dog Food")
    end

    it "author" do
      expect(subject.author).to eq("type"=>"Person", "id"=>"https://orcid.org/0000-0003-1419-2405", "name"=>"Fenner, Martin", "givenName"=>"Martin", "familyName"=>"Fenner")
    end

    it "date_published" do
      expect(subject.date_published).to eq("2016-12-20")
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
      expect(subject.title).to eq("Data from: A new malaria agent in African hominids.")
    end

    it "author" do
      expect(subject.author.length).to eq(8)
      expect(subject.author.first).to eq("type"=>"Person", "name"=>"Benjamin Ollomo", "givenName"=>"Benjamin", "familyName"=>"Ollomo")
    end

    it "date_published" do
      expect(subject.date_published).to eq("2011")
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
      expect(subject.title).to eq("Automated quantitative histology reveals vascular morphodynamics during Arabidopsis hypocotyl secondary growth")
    end

    it "author" do
      expect(subject.author.length).to eq(5)
      expect(subject.author.first).to eq("type"=>"Person", "name"=>"Martial Sankar", "givenName"=>"Martial", "familyName"=>"Sankar")
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
      expect(subject.title).to eq("Automated quantitative histology reveals vascular morphodynamics during Arabidopsis hypocotyl secondary growth")
    end

    it "author" do
      expect(subject.author.length).to eq(5)
      expect(subject.author.first).to eq("type"=>"Person", "name"=>"Martial Sankar", "givenName"=>"Martial", "familyName"=>"Sankar")
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
      expect(subject.title).to eq("Eating your own Dog Food")
    end

    it "author" do
      expect(subject.author).to eq("type"=>"Person", "name"=>"Martin Fenner", "givenName"=>"Martin", "familyName"=>"Fenner")
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
      expect(subject.title).to eq("R Interface to the DataONE REST API")
    end

    it "author" do
      expect(subject.author.length).to eq(3)
      expect(subject.author.first).to eq("type"=>"Person", "id"=>"http://orcid.org/0000-0003-0077-4738", "name"=>"Matt Jones", "givenName"=>"Matt", "familyName"=>"Jones")
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
      expect(subject.title).to eq("Analysis Tools for Crossover Experiment of UI using Choice Architecture")
    end

    it "author" do
      expect(subject.author).to eq("type"=>"Person", "name"=>"Kristian Garza", "givenName"=>"Kristian", "familyName"=>"Garza")
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
      expect(subject.title).to eq("Eating your own Dog Food")
    end

    it "author" do
      expect(subject.author).to eq("type"=>"Person", "id"=>"http://orcid.org/0000-0003-1419-2405", "name"=>"Martin Fenner", "givenName"=>"Martin", "familyName"=>"Fenner")
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
      expect(json["title"]).to eq("Eating your own Dog Food")
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
      expect(ttl[2]).to eq("<https://doi.org/10.5438/0000-00ss> a schema:CreativeWork .")
    end
  end
end
