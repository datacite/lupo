require 'rails_helper'

describe EventsQuery, elasticsearch: true do
  # before(:each) { allow(Time.zone).to receive(:now).and_return(Time.mktime(2015, 4, 8)) }

  context "citation events" do
    subject { create(:event_for_datacite_related) }
   
    it "doi_citations" do
      expect(EventsQuery.new.doi_citations(subject.obj_id.gsub("https://doi.org/",""))).to eq(1)
    end

    it "doi_citations wiht 0 citations" do
      expect(EventsQuery.new.doi_citations("10.5061/dryad.dd47sd5/1")).to eq(0)
    end

    it "citations" do
      expect(EventsQuery.new.citations("10.5061/dryad.47sd5/1,10.5061/dryad.47sd5/2,10.5061/dryad.47sd5/3")).to eq(1)
    end
  end
end
