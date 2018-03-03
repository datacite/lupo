require 'rails_helper'

describe Doi, vcr: true do
  subject { create(:doi, url: "https://blog.datacite.org/re3data-science-europe/") }

  context "landing page" do
    it 'get info' do
      expect(subject.get_landing_page_info["status"]).to eq(200)
      expect(subject.get_landing_page_info["content-type"]).to eq("text/html")
    end

    it 'content type pdf' do
      subject = create(:doi, url: "https://schema.datacite.org/meta/kernel-4.1/doc/DataCite-MetadataKernel_v4.1.pdf")
      expect(subject.get_landing_page_info["status"]).to eq(200)
      expect(subject.get_landing_page_info["content-type"]).to eq("application/pdf")
    end

    it 'not found' do
      subject = create(:doi, url: "https://blog.datacite.org/xxx")
      expect(subject.get_landing_page_info["status"]).to eq(404)
    end

    it 'no url' do
      subject = create(:doi, url: nil)
      expect(subject.get_landing_page_info["status"]).to eq(404)
    end
  end
end
