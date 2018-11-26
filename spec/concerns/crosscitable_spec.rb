require 'rails_helper'

describe Doi, vcr: true do
  let(:xml) { file_fixture('datacite.xml').read }

  subject { create(:doi, xml: xml) }

  context "from_xml" do
    it "from_xml" do
      string = file_fixture('datacite.xml').read
      expect(subject.from_xml(string)).to be_nil
      expect(subject.errors).to be_empty
    end

    it "from_xml malformed" do
      string = file_fixture('datacite_malformed.xml').read
      expect(subject.from_xml(string)).to eq(string)
      expect(subject.errors.messages).to eq(xml: ["Premature end of data in tag resource line 2 at line 40, column 1"])
    end
  end

  context "from_json" do
    it "from_json" do
      string = file_fixture('citeproc.json').read
      expect(subject.from_json(string)).to be_nil
      expect(subject.errors).to be_empty
    end

    it "from_json malformed" do
      string = file_fixture('citeproc_malformed.json').read
      expect(subject.from_json(string)).to eq(string)
      expect(subject.errors.messages).to eq(xml: ["Expected comma, not a string at line 4, column 9 [parse.c:381]"])
    end

    it "from_json duplicate keys" do
      string = file_fixture('citeproc_duplicate_keys.json').read
      expect(subject.from_json(string)).to eq(string)
      expect(subject.errors.messages).to eq(xml: ["The same key is defined more than once: id"])
    end
  end

  context "well_formed_xml" do
    it "from_xml" do
      string = file_fixture('datacite.xml').read
      expect(subject.well_formed_xml(string)).to eq(string)
      expect(subject.errors).to be_empty
    end

    it "from_xml malformed" do
      string = file_fixture('datacite_malformed.xml').read
      expect(subject.well_formed_xml(string)).to eq(string)
      expect(subject.errors.messages).to eq(xml: ["Premature end of data in tag resource line 2 at line 40, column 1"])
    end

    it "from_json" do
      string = file_fixture('citeproc.json').read
      expect(subject.well_formed_xml(string)).to eq(string)
      expect(subject.errors).to be_empty
    end

    it "from_json malformed" do
      string = file_fixture('citeproc_malformed.json').read
      expect(subject.well_formed_xml(string)).to eq(string)
      expect(subject.errors.messages).to eq(xml: ["Expected comma, not a string at line 4, column 9 [parse.c:381]"])
    end

    it "from_json duplicate keys" do
      string = file_fixture('citeproc_duplicate_keys.json').read
      expect(subject.well_formed_xml(string)).to eq(string)
      expect(subject.errors.messages).to eq(xml: ["The same key is defined more than once: id"])
    end
  end

  context "get attributes" do
    it "creator" do
      expect(subject.creator).to eq([{"familyName"=>"Fenner", "givenName"=>"Martin", "id"=>"https://orcid.org/0000-0003-1419-2405", "name"=>"Fenner, Martin", "type"=>"Person"}])
    end

    it "title" do
      expect(subject.titles).to eq([{"title"=>"Eating your own Dog Food"}])
    end

    it "publisher" do
      expect(subject.publisher).to eq("DataCite")
    end

    it "date_published" do
      expect(subject.dates).to eq([{"date"=>"2016-12-20", "dateType"=>"Created"}, {"date"=>"2016-12-20", "dateType"=>"Issued"}, {"date"=>"2016-12-20", "dateType"=>"Updated"}])
    end

    it "resource_type_general" do
      expect(subject.types).to eq("bibtex"=>"article", "citeproc"=>"article-journal", "resourceType"=>"BlogPosting", "resourceTypeGeneral"=>"Text", "ris"=>"RPRT", "schemaOrg"=>"ScholarlyArticle")
    end
  end

  context "set attributes" do
    it "creator" do
      creator = { "name" => "Carberry, Josiah"}
      subject.creator = creator
      expect(subject.creator).to eq(creator)
    end

    it "titles" do
      titles = [{ "title" => "Referee report." }]
      subject.titles = titles
      expect(subject.titles).to eq(titles)
    end

    it "publisher" do
      publisher = "Zenodo"
      subject.publisher = publisher
      expect(subject.publisher).to eq(publisher)
    end

    it "date_published" do
      date = "2018-03-01"
      subject.set_date(subject.dates, date, "Issued")
      expect(subject.dates).to eq([{"date"=>"2016-12-20", "dateType"=>"Created"}, {"date"=>"2018-03-01", "dateType"=>"Issued"}, {"date"=>"2016-12-20", "dateType"=>"Updated"}])
    end

    it "resource_type_general" do
      resource_type_general = "Software"
      subject.set_type(subject.types, resource_type_general, "resource_type_general")
      expect(subject.types).to eq("bibtex"=>"article", "citeproc"=>"article-journal", "resourceType"=>"BlogPosting", "resourceTypeGeneral"=>"Text", "resource_type_general"=>"Software", "ris"=>"RPRT", "schemaOrg"=>"ScholarlyArticle")
    end
  end
end
