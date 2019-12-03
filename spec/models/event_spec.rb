require 'rails_helper'

describe Event, :type => :model, vcr: true do
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

  context "citation" do
    subject { create(:event_for_datacite_related) }
   
    it "has citation_id" do
      expect(subject.citation_id).to eq("https://doi.org/10.5061/dryad.47sd5/1-https://doi.org/10.5061/dryad.47sd5e/1")
    end

    it "has link_types" do
      expect(subject.link_types).to eq(["10.5061/dryad.47sd5/1-citation", "10.5061/dryad.47sd5e/2-reference"])
    end
  
    it "has citation_year" do
      expect(subject.citation_year).to eq(2015)
    end
  
    it "has published_dates" do
      expect(subject.subj["datePublished"]).to eq("2006-06-13T16:14:19Z")
      expect(subject.obj["datePublished"]).to be_nil
    end

    let(:doi) { create(:doi) }

    it "date_published from the database" do
      published = subject.date_published("https://doi.org/"+doi.doi)
      expect(published).to eq("2011")
      expect(published).not_to eq(2011)
    end
  end
end
