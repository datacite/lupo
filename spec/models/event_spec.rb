require "rails_helper"

describe Event, type: :model, vcr: true do
  before(:each) { allow(Time.zone).to receive(:now).and_return(Time.mktime(2015, 4, 8)) }
  
  context "event" do
    subject { create(:event) }

    it { is_expected.to validate_presence_of(:subj_id) }
    it { is_expected.to validate_presence_of(:source_token) }
    it { is_expected.to validate_presence_of(:source_id) }

    it "has subj" do
      expect(subject.subj["datePublished"]).to eq("2006-06-13T16:14:19Z")
    end
  end

  context "class_methods" do
    it "import_doi crossref" do
      id = "10.1371/journal.pbio.2001414"
      doi = Event.import_doi(id)
      expect(doi.doi).to eq("10.1371/JOURNAL.PBIO.2001414")
      expect(doi.agency).to eq("crossref")
      expect(doi.types).to eq("bibtex"=>"article", "citeproc"=>"article-journal", "resourceType"=>"JournalArticle", "resourceTypeGeneral"=>"Text", "ris"=>"JOUR", "schemaOrg"=>"ScholarlyArticle")
      expect(doi.titles).to eq([{"title"=>"Identifiers for the 21st century: How to design, provision, and reuse persistent identifiers to maximize utility and impact of life science data"}])
      expect(doi.schema_version).to eq("http://datacite.org/schema/kernel-4")
      expect(doi.datacentre).to eq(0)
    end

    it "import_doi medra" do
      id = "10.3280/ecag2018-001005"
      doi = Event.import_doi(id)
      expect(doi.doi).to eq("10.3280/ECAG2018-001005")
      expect(doi.agency).to eq("medra")
      expect(doi.types).to eq("bibtex"=>"article", "citeproc"=>"article-journal", "resourceType"=>"JournalArticle", "resourceTypeGeneral"=>"Text", "ris"=>"JOUR", "schemaOrg"=>"ScholarlyArticle")
      expect(doi.titles).to eq([{"title"=>"Substitutability between organic and conventional poultry products and organic price premiums"}])
      expect(doi.datacentre).to eq(0)
    end

    it "import_doi kisti" do
      id = "10.5012/bkcs.2013.34.10.2889"
      doi = Event.import_doi(id)
      expect(doi.doi).to eq("10.5012/BKCS.2013.34.10.2889")
      expect(doi.agency).to eq("kisti")
      expect(doi.types).to eq("bibtex"=>"article", "citeproc"=>"article-journal", "resourceType"=>"JournalArticle", "resourceTypeGeneral"=>"Text", "ris"=>"JOUR", "schemaOrg"=>"ScholarlyArticle")
      expect(doi.titles).to eq([{"title"=>"Synthesis, Crystal Structure and Theoretical Calculation of a Novel Nickel(II) Complex with Dibromotyrosine and 1,10-Phenanthroline"}])
      expect(doi.datacentre).to eq(0)
    end

    it "import_doi jalc" do
      id = "10.1241/johokanri.39.979"
      doi = Event.import_doi(id)
      expect(doi.doi).to eq("10.1241/JOHOKANRI.39.979")
      expect(doi.agency).to eq("jalc")
      expect(doi.types).to eq("bibtex"=>"article", "citeproc"=>"article-journal", "resourceType"=>"JournalArticle", "resourceTypeGeneral"=>"Text", "ris"=>"JOUR", "schemaOrg"=>"ScholarlyArticle")
      expect(doi.titles).to eq([{"title"=>"Utilizing the Internet. 12 Series. Future of the Internet."}])
      expect(doi.datacentre).to eq(0)
    end

    it "import_doi op" do
      id = "10.2903/j.efsa.2018.5239"
      doi = Event.import_doi(id)
      expect(doi.doi).to eq("10.2903/J.EFSA.2018.5239")
      expect(doi.agency).to eq("op")
      expect(doi.types).to eq("bibtex"=>"article", "citeproc"=>"article-journal", "resourceType"=>"JournalArticle", "resourceTypeGeneral"=>"Text", "ris"=>"JOUR", "schemaOrg"=>"ScholarlyArticle")
      expect(doi.titles).to eq([{"title"=>"Scientific opinion on the safety of green tea catechins"}])
      expect(doi.datacentre).to eq(0)
    end

    it "import_doi datacite" do
      id = "10.5061/dryad.8515"
      doi = Event.import_doi(id)
      expect(doi).to be_nil
    end

    it "import_doi invalid doi" do
      id = "20.5061/dryad.8515"
      doi = Event.import_doi(id)
      expect(doi).to be_nil
    end
  end

  context "citation" do
    subject { create(:event_for_datacite_related, subj_id: "https://doi.org/10.5061/dryad.47sd5e/2") }

    it "has citation_id" do
      expect(subject.citation_id).to eq("https://doi.org/10.5061/dryad.47sd5/1-https://doi.org/10.5061/dryad.47sd5e/2")
    end

    it "has citation_year" do
      expect(subject.citation_year).to eq(2015)
    end

    let(:doi) { create(:doi) }

    it "date_published from the database" do
      published = subject.date_published("https://doi.org/" + doi.doi)
      expect(published).to eq("2011")
      expect(published).not_to eq(2011)
    end

    it "label_state_event with not existent prefix" do
      expect(Event.find_by(uuid: subject.uuid ).state_event).to be_nil
      Event.label_state_event({uuid:subject.uuid , subj_id:subject.subj_id})
      expect(Event.find_by(uuid: subject.uuid ).state_event).to eq("crossref_citations_error")
    end

    context "prefix exists, then dont to change" do
      let!(:prefix) { create(:prefix, uid: "10.5061") }
      it "label_state_event with  existent prefix" do
        expect(Event.find_by(uuid: subject.uuid ).state_event).to be_nil
        Event.label_state_event({uuid:subject.uuid , subj_id:subject.subj_id})
        expect(Event.find_by(uuid: subject.uuid ).state_event).to be_nil
      end
    end

    # context "double_crossref_check", elasticsearch: true do
    #   let(:provider) { create(:provider, symbol: "DATACITE") }
    #   let(:client) { create(:client, provider: provider, symbol: ENV['MDS_USERNAME'], password: ENV['MDS_PASSWORD']) }
    #   let!(:prefix) { create(:prefix, prefix: "10.14454") }
    #   let!(:client_prefix) { create(:client_prefix, client: client, prefix: prefix) }
    #   let!(:doi) { create(:doi, client: client) }
    #   let!(:dois)  { create_list(:doi, 10) }
    #   let!(:events) { create_list(:event_for_datacite_related, 30, source_id: "datacite-crossref", obj_id: doi.doi) }
 
    #   before do
    #     Provider.import
    #     Client.import
    #     DataciteDoi.import
    #     Event.import
    #     sleep 3
    #   end
      
    #   it "check run" do
    #     expect(Event.subj_id_check(cursor: [Event.minimum(:id),Event.maximum(:id)])).to eq(true)
    #   end
    # end
  end

  context "crossref" do
    subject { create(:event_for_crossref) }

    it "creates event" do
      expect(subject.subj_id).to eq("https://doi.org/10.1371/journal.pbio.2001414")
      expect(subject.obj_id).to eq("https://doi.org/10.5061/dryad.47sd5e/1")
      expect(subject.relation_type_id).to eq("references")
      expect(subject.source_id).to eq("crossref")
      expect(subject.dois_to_import).to eq(["10.1371/journal.pbio.2001414"])
    end
  end

  context "crossref import" do
    subject { create(:event_for_crossref_import) }

    it "creates event" do
      expect(subject.subj_id).to eq("https://doi.org/10.1371/journal.pbio.2001414")
      expect(subject.obj_id).to be_nil
      expect(subject.relation_type_id).to eq("references")
      expect(subject.source_id).to eq("crossref_import")
      expect(subject.dois_to_import).to eq(["10.1371/journal.pbio.2001414"])
    end
  end

  context "datacite orcid auto-update" do
    subject { create(:event_for_datacite_orcid_auto_update) }

    it "creates event" do
      expect(subject.subj_id).to eq("https://doi.org/10.5061/dryad.47sd5e/1")
      expect(subject.obj_id).to eq("https://orcid.org/0000-0003-1419-2111")
      expect(subject.relation_type_id).to eq("is-authored-by")
      expect(subject.source_id).to eq("datacite-orcid-auto-update")
      expect(subject.dois_to_import).to eq([])
    end
  end

  context "datacite funder" do
    subject { create(:event_for_datacite_funder) }

    it "creates event" do
      expect(subject.subj_id).to eq("https://doi.org/10.5061/dryad.47sd5e/1")
      expect(subject.obj_id).to eq("https://doi.org/10.13039/100000001")
      expect(subject.relation_type_id).to eq("is-funded-by")
      expect(subject.source_id).to eq("datacite_funder")
      expect(subject.dois_to_import).to eq([])
    end
  end

  context "datacite versions" do
    subject { create(:event_for_datacite_versions) }

    it "creates event" do
      expect(subject.subj_id).to eq("https://doi.org/10.5061/dryad.47sd5")
      expect(subject.obj_id).to eq("https://doi.org/10.5061/dryad.47sd5/1")
      expect(subject.relation_type_id).to eq("has-version")
      expect(subject.source_id).to eq("datacite_related")
      expect(subject.dois_to_import).to eq([])
    end
  end

  describe "camelcase_nested_objects" do
    subject { create(:event_for_datacite_related) }

    it "should transform keys" do
      Event.camelcase_nested_objects(subject.uuid)
      expect(subject.subj.keys).to include("datePublished", "registrantId", "id")
    end
  end
end
