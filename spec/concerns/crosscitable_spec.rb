require 'rails_helper'

describe Doi, vcr: true do
  subject { create(:doi) }

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
