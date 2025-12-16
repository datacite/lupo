# frozen_string_literal: true

require "rails_helper"
include Passwordable

describe DataciteDoisController, type: :request, vcr: true do
  let(:admin) { create(:provider, symbol: "ADMIN") }
  let(:admin_bearer) { Client.generate_token(role_id: "staff_admin", uid: admin.symbol, password: admin.password) }
  let(:admin_headers) { { "HTTP_ACCEPT" => "application/vnd.api+json", "HTTP_AUTHORIZATION" => "Bearer " + admin_bearer } }

  let!(:prefix) { create(:prefix, uid: "10.14454") }
  let!(:client_prefix) { create(:client_prefix, client: client, prefix: prefix) }

  let(:doi) { create(:doi, client: client, doi: "10.14454/4K3M-NYVG") }
  let(:headers) { { "HTTP_ACCEPT" => "application/vnd.api+json", "HTTP_AUTHORIZATION" => "Bearer " + bearer } }

  describe "content_negotation", elasticsearch: true do
    let(:provider) { create(:provider, symbol: "DATACITE") }
    let(:client) { create(:client, provider: provider, symbol: ENV["MDS_USERNAME"], password: ENV["MDS_PASSWORD"]) }
    let(:bearer) { Client.generate_token(role_id: "client_admin", uid: client.symbol, provider_id: provider.symbol.downcase, client_id: client.symbol.downcase, password: client.password) }
    let!(:datacite_doi) { create(:doi, client: client, aasm_state: "findable", type: "DataciteDoi") }

    before do
      DataciteDoi.import
      sleep 2
    end

    context "no permission" do
      let(:datacite_doi) { create(:doi) }

      it "returns error message" do
        get "/dois/#{datacite_doi.doi}", nil, { "HTTP_ACCEPT" => "application/vnd.jats+xml", "HTTP_AUTHORIZATION" => "Bearer " + bearer }

        expect(last_response.status).to eq(404)
        expect(json).to eq("errors" => [{ "status" => "404", "title" => "The resource you are looking for doesn't exist." }])
      end
    end

    context "no authentication" do
      let(:datacite_doi) { create(:doi) }

      it "returns error message" do
        get "/dois/#{datacite_doi.doi}", nil, { "HTTP_ACCEPT" => "application/vnd.jats+xml" }

        expect(last_response.status).to eq(404)
        expect(json).to eq("errors" => [{ "status" => "404", "title" => "The resource you are looking for doesn't exist." }])
      end
    end

    context "application/vnd.jats+xml" do
      it "returns the Doi" do
        get "/dois/#{datacite_doi.doi}", nil, { "HTTP_ACCEPT" => "application/vnd.jats+xml", "HTTP_AUTHORIZATION" => "Bearer " + bearer }

        expect(last_response.status).to eq(200)
        jats = Maremma.from_xml(last_response.body).fetch("element_citation", {})
        expect(jats.dig("publication_type")).to eq("data")
        expect(jats.dig("data_title")).to eq("Data from: A new malaria agent in African hominids.")
      end
    end

    context "application/vnd.jats+xml link" do
      it "returns the Doi" do
        get "/dois/application/vnd.jats+xml/#{datacite_doi.doi}"

        expect(last_response.status).to eq(200)
        jats = Maremma.from_xml(last_response.body).fetch("element_citation", {})
        expect(jats.dig("publication_type")).to eq("data")
        expect(jats.dig("data_title")).to eq("Data from: A new malaria agent in African hominids.")
      end
    end

    context "application/vnd.datacite.datacite+xml" do
      it "returns the Doi" do
        get "/dois/#{datacite_doi.doi}", nil, { "HTTP_ACCEPT" => "application/vnd.datacite.datacite+xml", "HTTP_AUTHORIZATION" => "Bearer " + bearer }

        expect(last_response.status).to eq(200)
        data = Maremma.from_xml(last_response.body).to_h.fetch("resource", {})
        expect(data.dig("xmlns")).to eq("http://datacite.org/schema/kernel-4")
        expect(data.dig("publisher")).to eq(
          {
            "__content__" => "Dryad Digital Repository",
            "publisherIdentifier" => "https://ror.org/00x6h5n95",
            "publisherIdentifierScheme" => "ROR",
            "schemeURI" => "https://ror.org/",
            "xml:lang" => "en"
          }
        )
        expect(data.dig("titles", "title")).to eq("Data from: A new malaria agent in African hominids.")
      end
    end

    context "application/vnd.datacite.datacite+xml link" do
      it "returns the Doi" do
        get "/dois/application/vnd.datacite.datacite+xml/#{datacite_doi.doi}"

        expect(last_response.status).to eq(200)
        data = Maremma.from_xml(last_response.body).to_h.fetch("resource", {})
        expect(data.dig("xmlns")).to eq("http://datacite.org/schema/kernel-4")
        expect(data.dig("publisher")).to eq(
          {
            "__content__" => "Dryad Digital Repository",
            "publisherIdentifier" => "https://ror.org/00x6h5n95",
            "publisherIdentifierScheme" => "ROR",
            "schemeURI" => "https://ror.org/",
            "xml:lang" => "en"
          }
        )
        expect(data.dig("titles", "title")).to eq("Data from: A new malaria agent in African hominids.")
      end
    end

    context "application/vnd.datacite.datacite+xml schema 3" do
      let(:xml) { file_fixture("datacite_schema_3.xml").read }
      let(:datacite_doi) { create(:doi, xml: xml, client: client, regenerate: false) }

      it "returns the Doi" do
        get "/dois/#{datacite_doi.doi}", nil, { "HTTP_ACCEPT" => "application/vnd.datacite.datacite+xml", "HTTP_AUTHORIZATION" => "Bearer " + bearer }

        expect(last_response.status).to eq(200)
        data = Maremma.from_xml(last_response.body).to_h.fetch("resource", {})
        expect(data.dig("xmlns")).to eq("http://datacite.org/schema/kernel-3")
        expect(data.dig("publisher")).to eq("Dryad Digital Repository")
        expect(data.dig("titles", "title")).to eq("Data from: A new malaria agent in African hominids.")
      end
    end

    # context "no metadata" do
    #   let(:doi) { create(:doi, xml: nil, client: client) }

    #   before { get "/#{doi.doi}", headers: { "HTTP_ACCEPT" => "application/vnd.datacite.datacite+xml", 'HTTP_AUTHORIZATION' => 'Bearer ' + bearer  } }

    #   it 'returns the Doi' do
    #     expect(last_response.body).to eq('')
    #   end

    #   it 'returns status code 200' do
    #     expect(response).to have_http_status(200)
    #   end
    # end

    context "application/vnd.datacite.datacite+xml not found" do
      it "returns error message" do
        get "/dois/xxx", nil, { "HTTP_ACCEPT" => "application/vnd.datacite.datacite+xml", "HTTP_AUTHORIZATION" => "Bearer " + bearer }

        expect(last_response.status).to eq(404)
        expect(json["errors"]).to eq([{ "status" => "404", "title" => "The resource you are looking for doesn't exist." }])
      end
    end

    context "application/vnd.datacite.datacite+json" do
      it "returns the Doi" do
        get "/dois/#{datacite_doi.doi}", nil, { "HTTP_ACCEPT" => "application/vnd.datacite.datacite+json", "HTTP_AUTHORIZATION" => "Bearer " + bearer }

        expect(last_response.status).to eq(200)
        expect(json["doi"]).to eq(datacite_doi.doi)
      end
    end

    context "application/vnd.datacite.datacite+json link" do
      it "returns the Doi" do
        get "/dois/application/vnd.datacite.datacite+json/#{datacite_doi.doi}"

        expect(last_response.status).to eq(200)
        expect(json["doi"]).to eq(datacite_doi.doi)
      end
    end

    context "application/vnd.crosscite.crosscite+json" do
      it "returns the Doi" do
        get "/dois/#{datacite_doi.doi}", nil, { "HTTP_ACCEPT" => "application/vnd.crosscite.crosscite+json", "HTTP_AUTHORIZATION" => "Bearer " + bearer }

        expect(last_response.status).to eq(200)
        expect(json["doi"]).to eq(datacite_doi.doi)
      end
    end

    context "application/vnd.crosscite.crosscite+json link" do
      it "returns the Doi" do
        get "/dois/application/vnd.crosscite.crosscite+json/#{datacite_doi.doi}"

        expect(last_response.status).to eq(200)
        expect(json["doi"]).to eq(datacite_doi.doi)
      end
    end

    context "application/vnd.schemaorg.ld+json" do
      it "returns the Doi" do
        get "/dois/#{datacite_doi.doi}", nil, { "HTTP_ACCEPT" => "application/vnd.schemaorg.ld+json", "HTTP_AUTHORIZATION" => "Bearer " + bearer }

        expect(last_response.status).to eq(200)
        expect(json["@type"]).to eq("Dataset")
      end
    end

    context "application/vnd.schemaorg.ld+json link" do
      it "returns the Doi" do
        get "/dois/application/vnd.schemaorg.ld+json/#{datacite_doi.doi}"

        expect(last_response.status).to eq(200)
        expect(json["@type"]).to eq("Dataset")
      end
    end

    context "application/ld+json" do
      it "returns the Doi" do
        get "/dois/#{datacite_doi.doi}", nil, { "HTTP_ACCEPT" => "application/ld+json", "HTTP_AUTHORIZATION" => "Bearer " + bearer }

        expect(last_response.status).to eq(200)
        expect(json["@type"]).to eq("Dataset")
      end
    end

    context "application/ld+json link" do
      it "returns the Doi" do
        get "/dois/application/ld+json/#{datacite_doi.doi}"

        expect(last_response.status).to eq(200)
        expect(json["@type"]).to eq("Dataset")
      end
    end

    context "application/vnd.citationstyles.csl+json" do
      it "returns the Doi" do
        get "/dois/#{datacite_doi.doi}", nil, { "HTTP_ACCEPT" => "application/vnd.citationstyles.csl+json", "HTTP_AUTHORIZATION" => "Bearer " + bearer }

        expect(last_response.status).to eq(200)
        expect(json).to eq({
          "type" => "dataset",
          "id" => "https://doi.org/#{datacite_doi.doi.downcase}",
          "categories" => [
            "Phylogeny",
            "Malaria",
            "Parasites",
            "Taxonomy",
            "Mitochondrial genome",
            "Africa",
            "Plasmodium"
          ],
          "author" => [
            { "family" => "Ollomo",
              "given" => "Benjamin" },
            { "family" => "Durand",
              "given" => "Patrick" },
            { "family" => "Prugnolle",
              "given" => "Franck" },
            { "family" => "Douzery",
              "given" => "Emmanuel J. P." },
            { "family" => "Arnathau",
              "given" => "Céline" },
            { "family" => "Nkoghe",
              "given" => "Dieudonné" },
            { "family" => "Leroy",
              "given" => "Eric" },
            { "family" => "Renaud",
              "given" => "François" }
            ],
          "issued" => { "date-parts" => [[2011]] },
          "abstract" => "Data from: A new malaria agent in African hominids.",
          "container-title" => "Physics letters / B",
          "DOI" => datacite_doi.doi,
          "volume" => "776",
          "page" => "249-264",
          "page-first" => "249",
          "publisher" => "Dryad Digital Repository",
          "title" => "Data from: A new malaria agent in African hominids.",
          "URL" => datacite_doi.url,
          "copyright" => "Creative Commons Zero v1.0 Universal"
        })
      end
    end

    context "application/vnd.citationstyles.csl+json link" do
      it "returns the Doi" do
        get "/dois/application/vnd.citationstyles.csl+json/#{datacite_doi.doi}"

        expect(last_response.status).to eq(200)
        expect(json["type"]).to eq("dataset")
      end
    end

    context "application/x-research-info-systems" do
      it "returns the Doi" do
        get "/dois/#{datacite_doi.doi}", nil, { "HTTP_ACCEPT" => "application/x-research-info-systems", "HTTP_AUTHORIZATION" => "Bearer " + bearer }

        expect(last_response.status).to eq(200)
        expect(last_response.body).to start_with("TY  - DATA")
      end
    end

    context "application/x-research-info-systems link" do
      it "returns the Doi" do
        get "/dois/application/x-research-info-systems/#{datacite_doi.doi}"

        expect(last_response.status).to eq(200)
        expect(last_response.body).to start_with("TY  - DATA")
      end
    end

    context "application/x-bibtex" do
      it "returns the Doi" do
        get "/dois/#{datacite_doi.doi}", nil, { "HTTP_ACCEPT" => "application/x-bibtex", "HTTP_AUTHORIZATION" => "Bearer " + bearer }

        expect(last_response.status).to eq(200)
        expect(last_response.body).to start_with("@misc{https://doi.org/#{datacite_doi.doi.downcase}")
      end
    end

    context "application/x-bibtex link" do
      it "returns the Doi" do
        get "/dois/application/x-bibtex/#{datacite_doi.doi}"

        expect(last_response.status).to eq(200)
        expect(last_response.body).to start_with("@misc{https://doi.org/#{datacite_doi.doi.downcase}")
      end
    end

    context "text/csv" do
      it "returns the Doi" do
        get "/dois/#{datacite_doi.doi}", nil, { "HTTP_ACCEPT" => "text/csv", "HTTP_AUTHORIZATION" => "Bearer " + bearer }

        expect(last_response.status).to eq(200)
        expect(last_response.body).to include(datacite_doi.doi)
      end
    end

    context "text/csv link" do
      it "returns the Doi" do
        get "/dois/text/csv/#{datacite_doi.doi}"

        expect(last_response.status).to eq(200)
        expect(last_response.body).to include(datacite_doi.doi)
      end
    end

    context "text/x-bibliography" do
      context "default style" do
        it "returns the Doi" do
          get "/dois/#{datacite_doi.doi}", nil, { "HTTP_ACCEPT" => "text/x-bibliography", "HTTP_AUTHORIZATION" => "Bearer " + bearer }

          expect(last_response.status).to eq(200)
          expect(last_response.body).to start_with("Ollomo, B.")
        end
      end

      context "default style link" do
        it "returns the Doi" do
          get "/dois/text/x-bibliography/#{datacite_doi.doi}"

          expect(last_response.status).to eq(200)
          expect(last_response.body).to start_with("Ollomo, B.")
        end
      end

      context "ieee style" do
        it "returns the Doi" do
          get "/dois/#{datacite_doi.doi}?style=ieee", nil, { "HTTP_ACCEPT" => "text/x-bibliography", "HTTP_AUTHORIZATION" => "Bearer " + bearer }

          expect(last_response.status).to eq(200)
          expect(last_response.body).to start_with("B. Ollomo")
        end
      end

      context "ieee style link" do
        it "returns the Doi" do
          get "/dois/text/x-bibliography/#{datacite_doi.doi}?style=ieee"

          expect(last_response.status).to eq(200)
          expect(last_response.body).to start_with("B. Ollomo")
        end
      end

      context "style and locale" do
        it "returns the Doi" do
          get "/dois/#{datacite_doi.doi}?style=vancouver&locale=de", nil, { "HTTP_ACCEPT" => "text/x-bibliography", "HTTP_AUTHORIZATION" => "Bearer " + bearer }

          expect(last_response.status).to eq(200)
          expect(last_response.body).to start_with("Ollomo B")
        end
      end
    end

    context "unknown content type" do
      it "returns the Doi" do
        get "/dois/#{datacite_doi.doi}", nil, { "HTTP_ACCEPT" => "application/vnd.ms-excel", "HTTP_AUTHORIZATION" => "Bearer " + bearer }

        expect(last_response.status).to eq(406)
        expect(json["errors"]).to eq([{ "status" => "406", "title" => "The content type is not recognized." }])
      end
    end

    context "missing content type" do
      it "returns the Doi" do
        get "/dois/#{datacite_doi.doi}", nil, { "HTTP_AUTHORIZATION" => "Bearer " + bearer }

        expect(last_response.status).to eq(200)
        expect(json.dig("data", "attributes", "doi")).to eq(datacite_doi.doi.downcase)
      end
    end
  end
end
