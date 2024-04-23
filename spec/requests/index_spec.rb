# frozen_string_literal: true

require "rails_helper"

describe IndexController, type: :request do
  let(:doi) { create(:doi, aasm_state: "findable") }

  describe "content_negotation" do
    context "application/vnd.jats+xml" do
      it "returns the Doi" do
        get "/#{doi.doi}",
            nil,
            { "HTTP_ACCEPT" => "application/vnd.jats+xml" }

        expect(last_response.status).to eq(200)
        jats =
          Maremma.from_xml(last_response.body).fetch("element_citation", {})
        expect(jats.dig("publication_type")).to eq("data")
        expect(jats.dig("data_title")).to eq(
          "Data from: A new malaria agent in African hominids.",
        )
      end
    end

    context "application/vnd.jats+xml link" do
      it "returns the Doi" do
        get "/application/vnd.jats+xml/#{doi.doi}"

        expect(last_response.status).to eq(200)
        jats =
          Maremma.from_xml(last_response.body).fetch("element_citation", {})
        expect(jats.dig("publication_type")).to eq("data")
        expect(jats.dig("data_title")).to eq(
          "Data from: A new malaria agent in African hominids.",
        )
      end
    end

    context "application/vnd.datacite.datacite+xml" do
      it "returns the Doi" do
        get "/#{doi.doi}",
            nil,
            {
              "HTTP_ACCEPT" => "application/vnd.datacite.datacite+xml",
            }

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
        expect(data.dig("titles", "title")).to eq(
          "Data from: A new malaria agent in African hominids.",
        )
      end
    end

    context "application/vnd.datacite.datacite+xml link" do
      it "returns the Doi" do
        get "/application/vnd.datacite.datacite+xml/#{doi.doi}"

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
        expect(data.dig("titles", "title")).to eq(
          "Data from: A new malaria agent in African hominids.",
        )
      end
    end

    context "application/vnd.datacite.datacite+xml not found" do
      it "returns error message" do
        get "/xxx",
            nil,
            {
              "HTTP_ACCEPT" => "application/vnd.datacite.datacite+xml",
            }

        expect(last_response.status).to eq(404)
        expect(json["errors"]).to eq(
          [
            {
              "status" => "404",
              "title" => "The resource you are looking for doesn't exist.",
            },
          ],
        )
      end
    end

    context "application/vnd.datacite.datacite+json" do
      it "returns the Doi" do
        get "/#{doi.doi}",
            nil,
            {
              "HTTP_ACCEPT" => "application/vnd.datacite.datacite+json",
            }

        expect(last_response.status).to eq(200)
        expect(json["doi"]).to eq(doi.doi)
      end
    end

    context "application/vnd.datacite.datacite+json link" do
      it "returns the Doi" do
        get "/application/vnd.datacite.datacite+json/#{doi.doi}"

        expect(last_response.status).to eq(200)
        expect(json["doi"]).to eq(doi.doi)
      end
    end

    context "application/vnd.crosscite.crosscite+json" do
      it "returns the Doi" do
        get "/#{doi.doi}",
            nil,
            {
              "HTTP_ACCEPT" => "application/vnd.crosscite.crosscite+json",
            }

        expect(last_response.status).to eq(200)
        expect(json["doi"]).to eq(doi.doi)
      end
    end

    context "application/vnd.crosscite.crosscite+json link" do
      it "returns the Doi" do
        get "/application/vnd.crosscite.crosscite+json/#{doi.doi}"

        expect(last_response.status).to eq(200)
        expect(json["doi"]).to eq(doi.doi)
      end
    end

    context "application/vnd.schemaorg.ld+json" do
      it "returns the Doi" do
        get "/#{doi.doi}",
            nil,
            { "HTTP_ACCEPT" => "application/vnd.schemaorg.ld+json" }

        expect(last_response.status).to eq(200)
        expect(json["@type"]).to eq("Dataset")
      end
    end

    context "application/vnd.schemaorg.ld+json link" do
      it "returns the Doi" do
        get "/application/vnd.schemaorg.ld+json/#{doi.doi}"

        expect(last_response.status).to eq(200)
        expect(json["@type"]).to eq("Dataset")
      end
    end

    context "application/ld+json" do
      it "returns the Doi" do
        get "/#{doi.doi}",
            nil, { "HTTP_ACCEPT" => "application/ld+json" }

        expect(last_response.status).to eq(200)
        expect(json["@type"]).to eq("Dataset")
      end
    end

    context "application/ld+json link" do
      it "returns the Doi" do
        get "/application/ld+json/#{doi.doi}"

        expect(last_response.status).to eq(200)
        expect(json["@type"]).to eq("Dataset")
      end
    end

    context "application/vnd.citationstyles.csl+json" do
      it "returns the Doi" do
        get "/#{doi.doi}",
            nil,
            {
              "HTTP_ACCEPT" => "application/vnd.citationstyles.csl+json",
            }

        expect(last_response.status).to eq(200)
        expect(json["type"]).to eq("dataset")
      end
    end

    context "application/vnd.citationstyles.csl+json link" do
      it "returns the Doi" do
        get "/application/vnd.citationstyles.csl+json/#{doi.doi}"

        expect(last_response.status).to eq(200)
        expect(json["type"]).to eq("dataset")
      end
    end

    context "application/x-research-info-systems" do
      it "returns the Doi" do
        get "/#{doi.doi}",
            nil,
            { "HTTP_ACCEPT" => "application/x-research-info-systems" }

        expect(last_response.status).to eq(200)
        expect(last_response.body).to start_with("TY  - DATA")
      end
    end

    context "application/x-research-info-systems link" do
      it "returns the Doi" do
        get "/application/x-research-info-systems/#{doi.doi}"

        expect(last_response.status).to eq(200)
        expect(last_response.body).to start_with("TY  - DATA")
      end
    end

    context "application/x-bibtex" do
      it "returns the Doi" do
        get "/#{doi.doi}",
            nil, { "HTTP_ACCEPT" => "application/x-bibtex" }

        expect(last_response.status).to eq(200)
        expect(last_response.body).to start_with(
          "@misc{https://doi.org/#{doi.doi.downcase}",
        )
      end
    end

    context "application/x-bibtex link" do
      it "returns the Doi" do
        get "/application/x-bibtex/#{doi.doi}"

        expect(last_response.status).to eq(200)
        expect(last_response.body).to start_with(
          "@misc{https://doi.org/#{doi.doi.downcase}",
        )
      end
    end

    context "text/csv" do
      it "returns the Doi" do
        get "/#{doi.doi}", nil, { "HTTP_ACCEPT" => "text/csv" }

        expect(last_response.status).to eq(200)
        expect(last_response.body).to include(doi.doi)
      end
    end

    context "text/csv link" do
      it "returns the Doi" do
        get "/text/csv/#{doi.doi}"

        expect(last_response.status).to eq(200)
        expect(last_response.body).to include(doi.doi)
      end
    end

    context "text/x-bibliography" do
      context "default style" do
        it "returns the Doi" do
          get "/#{doi.doi}",
              nil, { "HTTP_ACCEPT" => "text/x-bibliography" }

          expect(last_response.status).to eq(200)
          expect(last_response.body).to start_with("Ollomo, B.")
        end
      end

      it "header with style" do
        get "/#{doi.doi}",
            nil,
            { "HTTP_ACCEPT" => "text/x-bibliography; style=ieee" }

        expect(last_response.status).to eq(200)
        expect(last_response.body).to start_with("B. Ollomo")
      end

      it "header with style and locale" do
        get "/#{doi.doi}",
            nil,
            {
              "HTTP_ACCEPT" => "text/x-bibliography; style=vancouver; locale=de",
            }

        expect(last_response.status).to eq(200)
        expect(last_response.body).to start_with("Ollomo B")
      end

      context "default style link" do
        it "returns the Doi" do
          get "/text/x-bibliography/#{doi.doi}"

          expect(last_response.status).to eq(200)
          expect(last_response.body).to start_with("Ollomo, B.")
        end
      end

      context "ieee style link" do
        it "returns the Doi" do
          get "/text/x-bibliography/#{doi.doi}?style=ieee"

          expect(last_response.status).to eq(200)
          expect(last_response.body).to start_with("B. Ollomo")
        end
      end
    end

    context "unknown content type" do
      it "returns the Doi" do
        get "/#{doi.doi}", nil, { "HTTP_ACCEPT" => "application/vnd.ms-excel" }

        expect(last_response.status).to eq(303)
        expect(last_response.headers["Location"]).to eq(doi.url)
      end
    end

    context "missing content type" do
      it "returns the Doi" do
        get "/#{doi.doi}"

        expect(last_response.status).to eq(303)
        expect(last_response.headers["Location"]).to eq(doi.url)
      end
    end
  end
end
