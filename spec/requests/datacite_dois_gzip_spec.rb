# frozen_string_literal: true

require "rails_helper"

describe DataciteDoisController, type: :request, vcr: true do
  let(:admin) { create(:provider, symbol: "ADMIN") }
  let(:admin_bearer) { Client.generate_token(role_id: "staff_admin", uid: admin.symbol, password: admin.password) }
  let(:admin_headers) { { "HTTP_ACCEPT" => "application/vnd.api+json", "HTTP_AUTHORIZATION" => "Bearer " + admin_bearer } }

  let(:provider) { create(:provider, symbol: "DATACITE") }
  let(:client) { create(:client, provider: provider, symbol: ENV["MDS_USERNAME"], password: ENV["MDS_PASSWORD"], re3data_id: "10.17616/r3xs37") }
  let!(:prefix) { create(:prefix, uid: "10.14454") }
  let!(:client_prefix) { create(:client_prefix, client: client, prefix: prefix) }

  let(:doi) { create(:doi, client: client, doi: "10.14454/4K3M-NYVG") }
  let(:bearer) { Client.generate_token(role_id: "client_admin", uid: client.symbol, provider_id: provider.symbol.downcase, client_id: client.symbol.downcase, password: client.password) }
  let(:headers) { { "HTTP_ACCEPT" => "application/vnd.api+json", "HTTP_AUTHORIZATION" => "Bearer " + bearer } }

  let(:head1) { { "HTTP_ACCEPT" => "application/vnd.api+json", "HTTP_AUTHORIZATION" => "Bearer " + bearer } }

=begin
  let(:head) do
    {
      "Content-Type" => "application/gzip",
      "Content-Encoding" => "gzip",
      "Accept" => "gzip",
      "Authorization" => "Bearer " + bearer,
    }
  end
=end

  describe "POST /dois" do
    context "when the request is valid" do
      let(:xml) { Base64.strict_encode64(file_fixture("datacite.xml").read) }
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "doi" => "10.14454/10703",
              "url" => "http://www.bl.uk/pdf/patspec.pdf",
              "xml" => xml,
              "source" => "test",
              "event" => "publish",
            },
          },
        }
      end

      it "creates a Doi" do
        post "/dois", valid_attributes, headers

        expect(last_response.status).to eq(201)
        expect(json.dig("data", "attributes", "url")).to eq("http://www.bl.uk/pdf/patspec.pdf")
        expect(json.dig("data", "attributes", "doi")).to eq("10.14454/10703")
        expect(json.dig("data", "attributes", "titles")).to eq([{ "title" => "Eating your own Dog Food" }])
        expect(json.dig("data", "attributes", "creators")).to eq([{ "affiliation" => [], "familyName" => "Fenner",
                                                                    "givenName" => "Martin",
                                                                    "name" => "Fenner, Martin",
                                                                    "nameIdentifiers" =>
            [{ "nameIdentifier" => "https://orcid.org/0000-0003-1419-2405",
               "nameIdentifierScheme" => "ORCID",
               "schemeUri" => "https://orcid.org" }] }])
        expect(json.dig("data", "attributes", "schemaVersion")).to eq("http://datacite.org/schema/kernel-4")
        expect(json.dig("data", "attributes", "source")).to eq("test")
        expect(json.dig("data", "attributes", "types")).to eq("bibtex" => "article", "citeproc" => "article-journal", "resourceType" => "BlogPosting", "resourceTypeGeneral" => "Text", "ris" => "RPRT", "schemaOrg" => "ScholarlyArticle")
        expect(json.dig("data", "attributes", "state")).to eq("findable")

        doc = Nokogiri::XML(Base64.decode64(json.dig("data", "attributes", "xml")), nil, "UTF-8", &:noblanks)
        expect(doc.at_css("identifier").content).to eq("10.14454/10703")
      end
    end

    context "when the request is valid random doi" do
      let(:xml) { Base64.strict_encode64(file_fixture("datacite.xml").read) }
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "prefix" => "10.14454",
              "url" => "http://www.bl.uk/pdf/patspec.pdf",
              "xml" => xml,
              "source" => "test",
              "event" => "publish",
            },
          },
        }
      end

      it "creates a Doi" do
        post "/dois", valid_attributes, headers

        expect(last_response.status).to eq(201)
        expect(json.dig("data", "attributes", "url")).to eq("http://www.bl.uk/pdf/patspec.pdf")
        expect(json.dig("data", "attributes", "doi")).to start_with("10.14454")
        expect(json.dig("data", "attributes", "titles")).to eq([{ "title" => "Eating your own Dog Food" }])
        expect(json.dig("data", "attributes", "creators")).to eq([{ "affiliation" => [], "familyName" => "Fenner",
                                                                    "givenName" => "Martin",
                                                                    "name" => "Fenner, Martin",
                                                                    "nameIdentifiers" =>
            [{ "nameIdentifier" => "https://orcid.org/0000-0003-1419-2405",
               "nameIdentifierScheme" => "ORCID",
               "schemeUri" => "https://orcid.org" }] }])
        expect(json.dig("data", "attributes", "schemaVersion")).to eq("http://datacite.org/schema/kernel-4")
        expect(json.dig("data", "attributes", "source")).to eq("test")
        expect(json.dig("data", "attributes", "types")).to eq("bibtex" => "article", "citeproc" => "article-journal", "resourceType" => "BlogPosting", "resourceTypeGeneral" => "Text", "ris" => "RPRT", "schemaOrg" => "ScholarlyArticle")
        expect(json.dig("data", "attributes", "state")).to eq("findable")

        doc = Nokogiri::XML(Base64.decode64(json.dig("data", "attributes", "xml")), nil, "UTF-8", &:noblanks)
        expect(doc.at_css("identifier").content).to start_with("10.14454")
      end
    end
  end

  describe "POST /dois" do
    context "when the request is valid" do
      let(:xml) { Base64.strict_encode64(file_fixture("datacite.xml").read) }
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "doi" => "10.14454/10703",
              "url" => "http://www.bl.uk/pdf/patspec.pdf",
              "xml" => xml,
              "source" => "test",
              "event" => "publish",
            },
          },
        }
      end

=begin
      let(:headers) do
        {
          "HTTP_AUTHORIZATION" => "Bearer " + bearer,
          "HTTP_ACCEPT" => "application/vnd.api+json",
        }
      end

      let(:headers) do
        {
        'Content-Type' => 'json',
        'Content-Encoding' => 'gzip',
        'ACCEPT'=>'json',
        'Authorization' => 'Bearer ' + bearer
        }
      end
=end

      let(:headers) do
        {
          'CONTENT_TYPE' => 'application/gzip',
          'CONTENT_ENCODING' => 'gzip',
          'HTTP_ACCEPT'=>'gzip',
          'HTTP_AUTHORIZATION' => 'Bearer ' + ENV['CLIENT_ADMIN_TOKEN'],
          'HTTP_CONTENT_ENCODING' => 'gzip',
          'HTTP_CONTENT_TYPE' => 'application/gzip',
          #'Authorization' => 'Bearer ' + ENV['CLIENT_ADMIN_TOKEN'],
          'Content-Type' => 'application/gzip',
          'Content-Encoding' => 'gzip',
          'Accept' => 'gzip',
        }
      end

      let(:valid_json) { valid_attributes.to_json }
      #let(:gzipped) { Base64.encode64(ActiveSupport::Gzip.compress(valid_attributes)) }
      let(:gzipped) { ActiveSupport::Gzip.compress(valid_json) }

      before do
        #post "/dois",  headers: headers, params: gzipped
        # post "/dois", :headers => headers, :params => gzipped
        # post "/dois", headers, gzipped
        post "/dois", gzipped, headers
      end

      it "creates a Doi - 1" do
        #post "/dois", params: gzipped, headers: headers
        #post "/dois", valid_attributes, headers
        #post "/dois", :params => valid_attributes, :headers => headers

        expect(last_response.status).to eq(201)
      end
    end
  end
end
