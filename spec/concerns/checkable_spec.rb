require 'rails_helper'

describe Doi, vcr: true do
  context "landing page url" do
    it 'get info' do
      url = "https://blog.datacite.org/re3data-science-europe/"
      response = Doi.get_landing_page_info(url: url)
      expect(response["status"]).to eq(200)
      expect(response["content-type"]).to eq("text/html")
    end

    it 'content type pdf' do
      url = "https://schema.datacite.org/meta/kernel-4.1/doc/DataCite-MetadataKernel_v4.1.pdf"
      response = Doi.get_landing_page_info(url: url)
      expect(response["status"]).to eq(200)
      expect(response["content-type"]).to eq("application/pdf")
    end

    it 'not found' do
      url = "https://blog.datacite.org/xxx"
      response = Doi.get_landing_page_info(url: url)
      expect(response["status"]).to eq(404)
    end

    it 'no url' do
      response = Doi.get_landing_page_info(url: nil)
      expect(response["status"]).to eq(404)
    end
  end

  context "landing page doi and url" do
    it 'get info' do
      doi = create(:doi, url: "https://blog.datacite.org/re3data-science-europe/")
      response = Doi.get_landing_page_info(doi: doi)
      expect(response["status"]).to eq(200)
      expect(response["content-type"]).to eq("text/html")
      expect(doi.last_landing_page_status).to eq(200)
      expect(doi.last_landing_page_content_type).to eq("text/html")
    end

    it 'content type pdf' do
      doi = create(:doi, url: "https://schema.datacite.org/meta/kernel-4.1/doc/DataCite-MetadataKernel_v4.1.pdf")
      response = Doi.get_landing_page_info(doi: doi)
      expect(response["status"]).to eq(200)
      expect(response["content-type"]).to eq("application/pdf")
      expect(doi.last_landing_page_status).to eq(200)
      expect(doi.last_landing_page_content_type).to eq("application/pdf")
    end

    it 'not found' do
      doi = create(:doi, url: "https://blog.datacite.org/xxx")
      response = Doi.get_landing_page_info(doi: doi)
      expect(response["status"]).to eq(404)
      expect(doi.last_landing_page_status).to eq(404)
    end

    it 'no url' do
      doi = create(:doi, url: nil)
      response = Doi.get_landing_page_info(doi: doi)
      expect(response["status"]).to eq(404)
      expect(doi.last_landing_page_status).to eq(nil)
    end
  end
end
