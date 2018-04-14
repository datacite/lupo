require 'rails_helper'

describe Doi, vcr: true do
  subject { create(:doi) }

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
      string = Base64.strict_encode64(file_fixture('datacite.xml').read)
      expect(subject.well_formed_xml(string)).to eq(Base64.decode64(string))
      expect(subject.errors).to be_empty
    end

    it "from_xml malformed" do
      string = Base64.strict_encode64(file_fixture('datacite_malformed.xml').read)
      expect(subject.well_formed_xml(string)).to eq(Base64.decode64(string))
      expect(subject.errors.messages).to eq(xml: ["Premature end of data in tag resource line 2 at line 40, column 1"])
    end

    it "from_json" do
      string = Base64.strict_encode64(file_fixture('citeproc.json').read)
      expect(subject.well_formed_xml(string)).to eq(Base64.decode64(string))
      expect(subject.errors).to be_empty
    end

    it "from_json malformed" do
      string = Base64.strict_encode64(file_fixture('citeproc_malformed.json').read)
      expect(subject.well_formed_xml(string)).to eq(Base64.decode64(string))
      expect(subject.errors.messages).to eq(xml: ["Expected comma, not a string at line 4, column 9 [parse.c:381]"])
    end

    it "from_json duplicate keys" do
      string = Base64.strict_encode64(file_fixture('citeproc_duplicate_keys.json').read)
      expect(subject.well_formed_xml(string)).to eq(Base64.decode64(string))
      expect(subject.errors.messages).to eq(xml: ["The same key is defined more than once: id"])
    end
  end

  context "get attributes" do
    it "crosscite" do
      expect(subject.crosscite["title"]).to eq("Referee report. For: RESEARCH-3482 [version 5; referees: 1 approved, 1 approved with reservations]")
    end

    it "author" do
      expect(subject.author).to eq("name"=>"D S")
    end

    it "title" do
      expect(subject.title).to eq("Referee report. For: RESEARCH-3482 [version 5; referees: 1 approved, 1 approved with reservations]")
    end

    it "publisher" do
      expect(subject.publisher).to eq("F1000 Research Limited")
    end

    it "date_published" do
      expect(subject.date_published).to eq("2017")
    end

    it "resource_type_general" do
      expect(subject.resource_type_general).to eq("Text")
    end
  end

  context "set attributes" do
    it "crosscite" do
      author = { "name" => "Carberry, Josiah"}
      subject.crosscite["author"] = author
      expect(subject.crosscite["author"]).to eq(author)
      expect(subject.author).to eq(author)
    end

    it "author" do
      author = { "name" => "Carberry, Josiah"}
      subject.author = author
      expect(subject.author).to eq(author)
    end

    it "title" do
      title = "Referee report."
      subject.title = title
      expect(subject.title).to eq(title)
    end

    it "publisher" do
      publisher = "Zenodo"
      subject.publisher = publisher
      expect(subject.publisher).to eq(publisher)
    end

    it "date_published" do
      expect(subject.date_published).to eq("2017")
    end

    it "resource_type_general" do
      resource_type_general = "Software"
      subject.resource_type_general = resource_type_general
      expect(subject.resource_type_general).to eq(resource_type_general)
    end
  end
end
