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
    end

    describe "findable" do
      it "can publish" do
        subject.publish
        expect(subject).to have_state(:findable)
      end
    end

    describe "flagged" do
      it "can flag" do
        subject.publish
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
        subject.publish
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

    # context "no url" do
    #   let(:provider)  { create(:provider, symbol: "ADMIN") }
    #   let(:client)  { create(:client, provider: provider) }
    #   let(:url) { "https://www.example.org" }
    #   subject { build(:doi, client: client, url: nil, current_user: current_user) }

    #   it "don't update state change" do
    #     subject.publish
    #     expect { subject.save }.not_to have_enqueued_job(HandleJob)
    #     expect(subject).to have_state(:findable)
    #   end

    #   it "update url change" do
    #     subject.publish
    #     subject.url = url
    #     expect { subject.save }.to have_enqueued_job(HandleJob)
    #   end
    # end
  end

  describe "descriptions" do
    let(:doi) { build(:doi) }

    it "hash" do
      doi.descriptions = [{ "description" => "This is a description." }]
      expect(doi.save).to be true
      expect(doi.errors.details).to be_empty
    end

    it "string" do
      doi.descriptions = ["This is a description."]
      expect(doi.save).to be false
      expect(doi.errors.details).to eq(:descriptions=>[{:error=>"Description 'This is a description.' should be an object instead of a string."}])
    end
  end

  describe "rights_list" do
    let(:doi) { build(:doi) }

    it "hash" do
      doi.rights_list = [{ "rights" => "Creative Commons Attribution 4.0 International license (CC BY 4.0)" }]
      expect(doi.save).to be true
      expect(doi.errors.details).to be_empty
    end

    it "string" do
      doi.rights_list = ["Creative Commons Attribution 4.0 International license (CC BY 4.0)"]
      expect(doi.save).to be false
      expect(doi.errors.details).to eq(:rights_list => [{:error=>"Rights 'Creative Commons Attribution 4.0 International license (CC BY 4.0)' should be an object instead of a string."}])
    end
  end

  describe "subjects" do
    let(:doi) { build(:doi) }

    it "hash" do
      doi.subjects = [{ "subject" => "Tree" }]
      expect(doi.save).to be true
      expect(doi.errors.details).to be_empty
    end

    it "string" do
      doi.subjects = ["Tree"]
      expect(doi.save).to be false
      expect(doi.errors.details).to eq(:subjects=>[{:error=>"Subject 'Tree' should be an object instead of a string."}])
    end
  end

  describe "dates" do
    let(:doi) { build(:doi) }

    it "full date" do
      doi.dates = [{ "date" => "2019-08-01" }]
      expect(doi.save).to be true
      expect(doi.errors.details).to be_empty
    end

    it "year-month" do
      doi.dates = [{ "date" => "2019-08" }]
      expect(doi.save).to be true
      expect(doi.errors.details).to be_empty
    end

    it "year" do
      doi.dates = [{ "date" => "2019" }]
      expect(doi.save).to be true
      expect(doi.errors.details).to be_empty
    end

    it "date range" do
      doi.dates = [{ "date" => "2019-07-31/2019-08-01" }]
      expect(doi.save).to be true
      expect(doi.errors.details).to be_empty
    end

    it "date range years" do
      doi.dates = [{ "date" => "2018/2019" }]
      expect(doi.save).to be true
      expect(doi.errors.details).to be_empty
    end

    it "datetime" do
      doi.dates = [{ "date" => "2019-08-01T20:28:15" }]
      expect(doi.save).to be true
      expect(doi.errors.details).to be_empty
    end

    it "string" do
      doi.dates = ["2019-08-01"]
      expect(doi.save).to be false
      expect(doi.errors.details).to eq(:dates=>[{:error=>"Date 2019-08-01 should be an object instead of a string."}])
    end

    # it "invalid" do
    #   doi.dates = [{ "date" => "08/01/2019" }]
    #   expect(doi.save).to be false
    #   expect(doi.errors.details).to eq(:dates=>[{:error=>"Date 08/01/2019 is not a valid date in ISO8601 format."}])
    # end

    # it "invalid datetime" do
    #   doi.dates = [{ "date" => "2019-08-01 20:28:15" }]
    #   expect(doi.save).to be false
    #   expect(doi.errors.details).to eq(:dates => [{:error=>"Date 2019-08-01 20:28:15 is not a valid date in ISO8601 format."}])
    # end
  end

  describe "metadata" do
    subject  { create(:doi) }

    it "valid" do
      expect(subject.valid?).to be true
    end

    it "titles" do
      expect(subject.titles).to eq([{"title"=>"Data from: A new malaria agent in African hominids."}])
    end

    it "creators" do
      expect(subject.creators.length).to eq(8)
      expect(subject.creators.first).to eq("familyName"=>"Ollomo", "givenName"=>"Benjamin", "name"=>"Benjamin Ollomo", "nameType"=>"Personal")
    end

    it "dates" do
      expect(subject.get_date(subject.dates, "Issued")).to eq("2011")
    end

    it "publication_year" do
      expect(subject.publication_year).to eq(2011)
    end

    it "schema_version" do
      expect(subject.schema_version).to eq("http://datacite.org/schema/kernel-4")
    end

    it "xml" do
      doc = Nokogiri::XML(subject.xml, nil, 'UTF-8', &:noblanks)
      expect(doc.at_css("identifier").content).to eq(subject.doi)
    end

    it "metadata" do
      doc = Nokogiri::XML(subject.metadata.first.xml, nil, 'UTF-8', &:noblanks)
      expect(doc.at_css("identifier").content).to eq(subject.doi)
    end

    it "namespace" do
      expect(subject.metadata.first.namespace).to eq("http://datacite.org/schema/kernel-4")
    end
  end

  describe "change metadata" do
    let(:xml) { File.read(file_fixture('datacite_f1000.xml')) }
    let(:title) { "Triose Phosphate Isomerase Deficiency Is Caused by Altered Dimerization–Not Catalytic Inactivity–of the Mutant Enzymes" }
    let(:creators) { [{ "name"=>"Ollomi, Benjamin" }, { "name"=>"Duran, Patrick" }] }
    let(:publisher) { "Zenodo" }
    let(:publication_year) { 2011 }
    let(:types) { { "resourceTypeGeneral" => "Software", "resourceType" => "BlogPosting", "schemaOrg" => "BlogPosting" } }
    let(:description) { "Eating your own dog food is a slang term to describe that an organization should itself use the products and services it provides. For DataCite this means that we should use DOIs with appropriate metadata and strategies for long-term preservation for..." }

    subject  { create(:doi, 
      xml: xml, 
      titles: [{ "title" => title }], 
      creators: creators,
      publisher: publisher,
      publication_year: publication_year,
      types: types,
      descriptions: [{ "description" => description }],
      event: "publish")
    }

    it "titles" do
      expect(subject.titles).to eq([{ "title" => title }])

      xml = Maremma.from_xml(subject.xml).fetch("resource", {})
      expect(xml.dig("titles", "title")).to eq(title)
    end

    it "creators" do
      expect(subject.creators).to eq(creators)

      xml = Maremma.from_xml(subject.xml).fetch("resource", {})
      expect(xml.dig("creators", "creator")).to eq([{"creatorName"=>"Ollomi, Benjamin"}, {"creatorName"=>"Duran, Patrick"}])
    end

    it "publisher" do
      expect(subject.publisher).to eq(publisher)

      xml = Maremma.from_xml(subject.xml).fetch("resource", {})
      expect(xml.dig("publisher")).to eq(publisher)
    end

    it "publication_year" do
      expect(subject.publication_year).to eq(2011)

      xml = Maremma.from_xml(subject.xml).fetch("resource", {})
      expect(xml.dig("publicationYear")).to eq("2011")
    end

    it "resource_type" do
      expect(subject.types["resourceType"]).to eq("BlogPosting")

      xml = Maremma.from_xml(subject.xml).fetch("resource", {})
      expect(xml.dig("resourceType")).to eq("resourceTypeGeneral"=>"Software", "__content__"=>"BlogPosting")
    end

    it "resource_type_general" do
      expect(subject.types["resourceTypeGeneral"]).to eq("Software")

      xml = Maremma.from_xml(subject.xml).fetch("resource", {})
      expect(xml.dig("resourceType")).to eq("resourceTypeGeneral"=>"Software", "__content__"=>"BlogPosting")
    end

    it "descriptions" do
      expect(subject.descriptions).to eq([{ "description" => description }])

      xml = Maremma.from_xml(subject.xml).fetch("resource", {})
      expect(xml.dig("descriptions", "description")).to eq("__content__" => "Eating your own dog food is a slang term to describe that an organization should itself use the products and services it provides. For DataCite this means that we should use DOIs with appropriate metadata and strategies for long-term preservation for...", "descriptionType" => "Abstract")
    end

    it "schema_version" do
      expect(subject.schema_version).to eq("http://datacite.org/schema/kernel-4")
      xml = Maremma.from_xml(subject.xml).fetch("resource", {})
      expect(xml.dig("xmlns")).to eq("http://datacite.org/schema/kernel-4")
      expect(subject.metadata.first.namespace).to eq("http://datacite.org/schema/kernel-4")
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

  describe "content negotiation" do
    subject { create(:doi, doi: "10.5438/4k3m-nyvg", event: "publish") }

    it "validates against schema" do
      expect(subject.valid?).to be true
    end

    it "generates datacite_xml" do
      doc = Nokogiri::XML(subject.xml, nil, 'UTF-8', &:noblanks)
      expect(doc.at_css("identifier").content).to eq(subject.doi)
    end

    it "generates bibtex" do
      bibtex = BibTeX.parse(subject.bibtex).to_a(quotes: '').first
      expect(bibtex[:bibtex_type].to_s).to eq("misc")
      expect(bibtex[:title].to_s).to eq("Data from: A new malaria agent in African hominids.")
    end

    it "generates ris" do
      ris = subject.ris.split("\r\n")
      expect(ris[0]).to eq("TY  - DATA")
      expect(ris[1]).to eq("T1  - Data from: A new malaria agent in African hominids.")
    end

    it "generates schema_org" do
      json = JSON.parse(subject.schema_org)
      expect(json["@type"]).to eq("Dataset")
      expect(json["name"]).to eq("Data from: A new malaria agent in African hominids.")
    end

    it "generates datacite_json" do
      json = JSON.parse(subject.datacite_json)
      expect(json["doi"]).to eq("10.5438/4K3M-NYVG")
      expect(json["titles"]).to eq([{"title"=>"Data from: A new malaria agent in African hominids."}])
    end

    it "generates codemeta" do
      json = JSON.parse(subject.codemeta)
      expect(json["@type"]).to eq("Dataset")
      expect(json["name"]).to eq("Data from: A new malaria agent in African hominids.")
    end

    it "generates jats" do
      jats = Maremma.from_xml(subject.jats).fetch("element_citation", {})
      expect(jats.dig("publication_type")).to eq("data")
      expect(jats.dig("data_title")).to eq("Data from: A new malaria agent in African hominids.")
    end
  end

  describe "import_by_ids", elasticsearch: true do
    let(:provider)  { create(:provider) }
    let(:client)  { create(:client, provider: provider) }
    let(:target) { create(:client, provider: provider, symbol: provider.symbol + ".TARGET", name: "Target Client") }
    let!(:dois) { create_list(:doi, 3, client: client, aasm_state: "findable") }
    let(:doi) { dois.first }

    it "import by ids" do
      response = Doi.import_by_ids
      expect(response).to be > 0
    end

    it "import by id" do
      response = Doi.import_by_id(id: doi.id)
      expect(response).to eq(3)
    end
  end

  describe "transfer", elasticsearch: true do
    let(:provider)  { create(:provider) }
    let(:client)  { create(:client, provider: provider) }
    let(:target) { create(:client, provider: provider, symbol: provider.symbol + ".TARGET", name: "Target Client") }
    let!(:dois) { create_list(:doi, 5, client: client, aasm_state: "findable") }

    before do
      Doi.import
      sleep 1
    end

    it "transfer all dois" do
      response = Doi.transfer(client_id: client.symbol.downcase, target_id: target.symbol.downcase, size: 3)
      expect(response).to eq(5)
    end
  end

  describe "views", elasticsearch: true do
    let(:client) { create(:client) }
    let(:doi) { create(:doi, client: client, aasm_state: "findable") }
    let!(:views) { create_list(:event_for_datacite_usage, 3, obj_id: "https://doi.org/#{doi.doi}", relation_type_id: "unique-dataset-investigations-regular", total: 25) }

    before do
      Doi.import
      sleep 1
    end

    it "has views" do
      expect(doi.views.count).to eq(3)
      expect(doi.view_count).to eq(75)
      expect(doi.views_over_time.first).to eq(:total=>25, :year_month=>"2015-06")

      view = doi.views.first
      expect(view.target_doi).to eq(doi.uid)
      expect(view.total).to eq(25)
    end
  end

  describe "downloads", elasticsearch: true do
    let(:client) { create(:client) }
    let(:doi) { create(:doi, client: client, aasm_state: "findable") }
    let!(:downloads) { create_list(:event_for_datacite_usage, 3, obj_id: "https://doi.org/#{doi.doi}", relation_type_id: "unique-dataset-requests-regular", total: 10) }

    before do
      Doi.import
      sleep 1
    end

    it "has downloads" do
      expect(doi.downloads.count).to eq(3)
      expect(doi.download_count).to eq(30)
      expect(doi.downloads_over_time.first).to eq(:total=>10, :year_month=>"2015-06")

      download = doi.downloads.first
      expect(download.target_doi).to eq(doi.uid)
      expect(download.total).to eq(10)
    end
  end

  describe "references", elasticsearch: true do
    let(:client) { create(:client) }
    let(:doi) { create(:doi, client: client, aasm_state: "findable") }
    let!(:references) { create_list(:event_for_crossref, 3, subj_id: "https://doi.org/#{doi.doi}", relation_type_id: "references") }

    before do
      Doi.import
      sleep 1
    end

    it "has references" do
      expect(doi.references.count).to eq(3)
      expect(doi.reference_ids.count).to eq(3)
      expect(doi.reference_count).to eq(3)

      reference = doi.references.first
      expect(reference.source_doi).to eq(doi.uid)
      expect(reference.total).to eq(1)
    end
  end

  describe "citations", elasticsearch: true do
    let(:client) { create(:client) }
    let(:doi) { create(:doi, client: client, aasm_state: "findable") }
    let!(:citations) { create_list(:event_for_datacite_crossref, 1, subj_id: "https://doi.org/#{doi.doi}", relation_type_id: "is-referenced-by") }

    before do
      Doi.import
      sleep 1
    end

    it "has citations" do
      expect(doi.citations.count).to eq(1)
      expect(doi.citation_ids.count).to eq(1)
      expect(doi.citation_count).to eq(1)

      citation = doi.citations.first
      expect(citation.target_doi).to eq(doi.uid)
      expect(citation.total).to eq(1)
    end
  end

  describe "parts", elasticsearch: true do
    let(:client) { create(:client) }
    let(:doi) { create(:doi, client: client, aasm_state: "findable") }
    let!(:parts) { create_list(:event_for_datacite_parts, 3, subj_id: "https://doi.org/#{doi.doi}", relation_type_id: "has-part") }

    before do
      Doi.import
      sleep 1
    end

    it "has parts" do
      expect(doi.parts.count).to eq(3)
      expect(doi.part_ids.count).to eq(3)
      expect(doi.part_count).to eq(3)

      part = doi.parts.first
      expect(part.source_doi).to eq(doi.uid)
      expect(part.total).to eq(1)
    end
  end

  describe "part of", elasticsearch: true do
    let(:client) { create(:client) }
    let(:doi) { create(:doi, client: client, aasm_state: "findable") }
    let!(:part_of) { create_list(:event_for_datacite_part_of, 1, subj_id: "https://doi.org/#{doi.doi}", relation_type_id: "is-part-of") }

    before do
      Doi.import
      sleep 1
    end

    it "has part of" do
      expect(doi.part_of.count).to eq(1)
      expect(doi.part_of_ids.count).to eq(1)
      expect(doi.part_of_count).to eq(1)

      part_of = doi.part_of.first
      expect(part_of.target_doi).to eq(doi.uid)
      expect(part_of.total).to eq(1)
    end
  end

  describe "versions", elasticsearch: true do
    let(:client) { create(:client) }
    let(:doi) { create(:doi, client: client, aasm_state: "findable") }
    let!(:versions) { create_list(:event_for_datacite_parts, 3, subj_id: "https://doi.org/#{doi.doi}", relation_type_id: "has-version") }

    before do
      Doi.import
      sleep 1
    end

    it "has versions" do
      expect(doi.versions.count).to eq(3)
      expect(doi.version_ids.count).to eq(3)
      expect(doi.version_count).to eq(3)

      version = doi.versions.first
      expect(version.source_doi).to eq(doi.uid)
      expect(version.total).to eq(1)
    end
  end

  describe "version of", elasticsearch: true do
    let(:client) { create(:client) }
    let(:doi) { create(:doi, client: client, aasm_state: "findable") }
    let!(:part_of) { create_list(:event_for_datacite_part_of, 1, subj_id: "https://doi.org/#{doi.doi}", relation_type_id: "is-version-of") }

    before do
      Doi.import
      sleep 1
    end

    it "has version of" do
      expect(doi.version_of.count).to eq(1)
      expect(doi.version_of_ids.count).to eq(1)
      expect(doi.version_of_count).to eq(1)

      version_of = doi.version_of.first
      expect(version_of.target_doi).to eq(doi.uid)
      expect(version_of.total).to eq(1)
    end
  end

  describe "convert_affiliations" do
    let(:doi) { create(:doi)}

    context "affiliation nil" do
      let(:creators) { [{
        "name": "Ausmees, K.",
        "nameType": "Personal",
        "givenName": "K.",
        "familyName": "Ausmees",
        "affiliation": nil
      }] }
      let(:doi) { create(:doi, creators: creators, contributors: [])}

      it "convert" do
        expect(Doi.convert_affiliation_by_id(id: doi.id)).to eq(1)
      end
    end

    context "affiliation empty array" do
      let(:creators) { [{
        "name": "Ausmees, K.",
        "nameType": "Personal",
        "givenName": "K.",
        "familyName": "Ausmees",
        "affiliation": []
      }] }
      let(:doi) { create(:doi, creators: creators, contributors: [])}

      it "convert" do
        expect(Doi.convert_affiliation_by_id(id: doi.id)).to eq(0)
      end
    end

    context "affiliation array of hashes" do
      let(:creators) { [{
        "name": "Ausmees, K.",
        "nameType": "Personal",
        "givenName": "K.",
        "familyName": "Ausmees",
        "affiliation": [{ "name": "Department of Microbiology; Tartu University; Tartu Estonia" }]
      }] }
      let(:doi) { create(:doi, creators: creators, contributors: [])}

      it "convert" do
        expect(Doi.convert_affiliation_by_id(id: doi.id)).to eq(0)
      end
    end

    context "affiliation hash" do
      let(:creators) { [{
        "name": "Ausmees, K.",
        "nameType": "Personal",
        "givenName": "K.",
        "familyName": "Ausmees",
        "affiliation": { "name": "Department of Microbiology; Tartu University; Tartu Estonia" }
      }] }
      let(:doi) { create(:doi, creators: creators, contributors: [])}

      it "convert" do
        expect(Doi.convert_affiliation_by_id(id: doi.id)).to eq(1)
      end
    end

    context "affiliation array of strings" do
      let(:creators) { [{
        "name": "Ausmees, K.",
        "nameType": "Personal",
        "givenName": "K.",
        "familyName": "Ausmees",
        "affiliation": ["Andrology Centre; Tartu University Hospital; Tartu Estonia", "Department of Surgery; Tartu University; Tartu Estonia"]
      }] }
      let(:doi) { create(:doi, creators: creators, contributors: [])}

      it "convert" do
        expect(Doi.convert_affiliation_by_id(id: doi.id)).to eq(1)
      end
    end

    context "affiliation string" do
      let(:creators) { [{
        "name": "Ausmees, K.",
        "nameType": "Personal",
        "givenName": "K.",
        "familyName": "Ausmees",
        "affiliation": "Andrology Centre; Tartu University Hospital; Tartu Estonia"
      }] }
      let(:doi) { create(:doi, creators: creators, contributors: [])}

      it "convert" do
        expect(Doi.convert_affiliation_by_id(id: doi.id)).to eq(1)
      end
    end
  end

  describe "convert_containers" do
    let(:doi) { create(:doi)}

    context "container nil" do
      let(:container) { nil }
      let(:doi) { create(:doi, container: container)}

      it "convert" do
        expect(Doi.convert_container_by_id(id: doi.id)).to eq(0)
      end
    end

    context "container hash with strings" do
      let(:container) { {
        "type": "Journal", 
        "issue": "6", 
        "title": "Journal of Crustacean Biology", 
        "volume": "32", 
        "lastPage": "961", 
        "firstPage": "949", 
        "identifier": "1937-240X", 
        "identifierType": "ISSN"
      } }
      let(:doi) { create(:doi, container: container)}

      it "not convert" do
        expect(Doi.convert_container_by_id(id: doi.id)).to eq(0)
      end
    end

    context "container hash with hashes" do
      let(:container) { {
        "type": "Journal", 
        "issue": { "xmlns:foaf": "http://xmlns.com/foaf/0.1/", "xmlns:rdfs": "http://www.w3.org/2000/01/rdf-schema#", "__content__": "6"}, 
        "title": { "xmlns:foaf": "http://xmlns.com/foaf/0.1/", "xmlns:rdfs": "http://www.w3.org/2000/01/rdf-schema#", "__content__": "Journal of Crustacean Biology"}, 
        "volume": { "xmlns:foaf": "http://xmlns.com/foaf/0.1/", "xmlns:rdfs": "http://www.w3.org/2000/01/rdf-schema#", "__content__": "32"}, 
        "lastPage": "961", 
        "firstPage": "949", 
        "identifier": "1937-240X", 
        "identifierType": "ISSN"
      } }
      let(:doi) { create(:doi, container: container)}

      it "convert" do
        expect(Doi.convert_container_by_id(id: doi.id)).to eq(1)
      end
    end
  end

  describe "migrates landing page" do
    let(:provider)  { create(:provider, symbol: "ADMIN") }
    let(:client)  { create(:client, provider: provider) }

    let(:last_landing_page_status_result) { {
      "error" => nil,
      "redirect-count" => 0,
      "redirect-urls" => ["http://example.com", "https://example.com"],
      "download-latency" => 200.323232,
      "has-schema-org" => true,
      "schema-org-id" => "10.14454/10703",
      "dc-identifier" => nil,
      "citation-doi" => nil,
      "body-has-pid" => true
    } }

    let(:timeNow) { Time.zone.now.iso8601 }

    let(:doi) {
      create(
        :doi,
        client: client,
        last_landing_page_status: 200,
        last_landing_page_status_check: timeNow,
        last_landing_page_content_type: "text/html",
        last_landing_page: "http://example.com",
        last_landing_page_status_result: last_landing_page_status_result
        )
    }

    let(:landing_page) { {
      "checked" => timeNow,
      "status" => 200,
      "url" => "http://example.com",
      "contentType" => "text/html",
      "error" => nil,
      "redirectCount" => 0,
      "redirectUrls" => ["http://example.com", "https://example.com"],
      "downloadLatency" => 200,
      "hasSchemaOrg" => true,
      "schemaOrgId" => "10.14454/10703",
      "dcIdentifier" => nil,
      "citationDoi" => nil,
      "bodyHasPid" => true
    } }

    before { doi.save }

    it "migrates and corrects data" do
      Doi.migrate_landing_page

      changed_doi = Doi.find(doi.id)

      expect(changed_doi.landing_page).to eq(landing_page)
    end
  end
end
