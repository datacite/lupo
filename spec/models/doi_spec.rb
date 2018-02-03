require 'rails_helper'

describe Doi, type: :model, vcr: true do
  it { should validate_presence_of(:doi) }

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
end
