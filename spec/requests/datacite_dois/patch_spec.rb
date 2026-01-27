# frozen_string_literal: true

require "rails_helper"
include Passwordable

describe DataciteDoisController, type: :request, vcr: true do
  let(:admin) { create(:provider, symbol: "ADMIN") }
  let(:admin_bearer) { Client.generate_token(role_id: "staff_admin", uid: admin.symbol, password: admin.password) }
  let(:admin_headers) { { "HTTP_ACCEPT" => "application/vnd.api+json", "HTTP_AUTHORIZATION" => "Bearer " + admin_bearer } }

  let(:provider) { create(:provider, symbol: "DATACITE", password: encrypt_password_sha256(ENV["MDS_PASSWORD"])) }
  let(:client) { create(:client, provider: provider, symbol: ENV["MDS_USERNAME"], password: encrypt_password_sha256(ENV["MDS_PASSWORD"]), re3data_id: "10.17616/r3xs37") }
  let!(:prefix) { create(:prefix, uid: "10.14454") }
  let!(:client_prefix) { create(:client_prefix, client: client, prefix: prefix) }

  let(:doi) { create(:doi, client: client, doi: "10.14454/4K3M-NYVG") }
  let(:bearer) { Client.generate_token(role_id: "client_admin", uid: client.symbol, provider_id: provider.symbol.downcase, client_id: client.symbol.downcase, password: client.password) }
  let(:headers) { { "HTTP_ACCEPT" => "application/vnd.api+json", "HTTP_AUTHORIZATION" => "Bearer " + bearer } }

  describe "PATCH /dois/:id" do
    context "when the record exists" do
      let(:xml) { Base64.strict_encode64(file_fixture("datacite.xml").read) }
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "url" => "http://www.bl.uk/pdf/pat.pdf",
              "xml" => xml,
            },
          },
        }
      end

      it "updates the record" do
        patch "/dois/#{doi.doi}", valid_attributes, headers

        expect(last_response.status).to eq(200)
        expect(json.dig("data", "attributes", "url")).to eq("http://www.bl.uk/pdf/pat.pdf")
        expect(json.dig("data", "attributes", "doi")).to eq(doi.doi.downcase)
        expect(json.dig("data", "attributes", "titles")).to eq([{ "title" => "Eating your own Dog Food" }])
      end

      it "sets state to draft" do
        patch "/dois/#{doi.doi}", valid_attributes, headers

        expect(json.dig("data", "attributes", "state")).to eq("draft")
      end
    end

    context "read-only attributes" do
      let(:xml) { Base64.strict_encode64(file_fixture("datacite.xml").read) }
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "url" => "http://www.bl.uk/pdf/pat.pdf",
              "xml" => xml,
              "container" => {},
              "published" => nil,
              "viewsOverTime" => {},
              "downloadsOverTime" => {},
              "citationsOverTime" => {},
              "viewCount" => 0,
              "downloadCount" => 0,
              "citationCount" => 0,
              "partCount" => 0,
              "partOfCount" => 0,
              "referenceCount" => 0,
              "versionCount" => 0,
              "versionOfCount" => 0,
            },
          },
        }
      end

      it "updates the record" do
        patch "/dois/#{doi.doi}", valid_attributes, headers

        expect(last_response.status).to eq(200)
        expect(json.dig("data", "attributes", "url")).to eq("http://www.bl.uk/pdf/pat.pdf")
        expect(json.dig("data", "attributes", "doi")).to eq(doi.doi.downcase)
        expect(json.dig("data", "attributes", "titles")).to eq([{ "title" => "Eating your own Dog Food" }])
      end
    end

    context "when the record exists no data attribute" do
      let(:xml) { Base64.strict_encode64(file_fixture("datacite.xml").read) }
      let(:valid_attributes) do
        {
          "url" => "http://www.bl.uk/pdf/pat.pdf",
          "xml" => xml,
        }
      end

      it "raises an error" do
        patch "/dois/#{doi.doi}", valid_attributes, headers

        expect(last_response.status).to eq(400)
        expect(json.dig("errors")).to eq([{ "status" => "400", "title" => "You need to provide a payload following the JSONAPI spec" }])
      end
    end

    context "update sizes" do
      let(:doi) { create(:doi, doi: "10.14454/10703", url: "https://datacite.org", client: client) }
      let(:sizes) { ["100 samples", "56 pages"] }
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "sizes" => sizes,
              "event" => "publish",
            },
          },
        }
      end

      it "updates the doi" do
        put "/dois/#{doi.doi}", valid_attributes, admin_headers

        expect(last_response.status).to eq(200)
        expect(json.dig("data", "attributes", "sizes")).to eq(sizes)
      end
    end

    context "update formats" do
      let(:doi) { create(:doi, doi: "10.14454/10703", url: "https://datacite.org", client: client) }
      let(:formats) { ["application/json"] }
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "formats" => formats,
              "event" => "publish",
            },
          },
        }
      end

      it "updates the doi" do
        put "/dois/#{doi.doi}", valid_attributes, admin_headers

        expect(last_response.status).to eq(200)
        expect(json.dig("data", "attributes", "formats")).to eq(formats)
      end
    end

    context "no creators validate" do
      let(:doi) { create(:doi, client: client, creators: nil) }
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "url" => "http://www.bl.uk/pdf/pat.pdf",
              "xml" => Base64.strict_encode64(doi.xml),
              "event" => "publish",
            },
          },
        }
      end

      it "returns error" do
        put "/dois/#{doi.doi}", valid_attributes, headers

        expect(last_response.status).to eq(422)
        expect(json["errors"]).to eq([{ "source" => "creators", "title" => "DOI #{doi.uid}: Missing child element(s). Expected is ( {http://datacite.org/schema/kernel-4}creator ). at line 4, column 0", "uid" => doi.uid }])
      end
    end

    context "when the record exists https://github.com/datacite/lupo/issues/89" do
      let(:doi) { create(:doi, doi: "10.14454/119496", url: "https://datacite.org", client: client) }
      let(:valid_attributes) { JSON.parse(file_fixture("datacite_89.json").read) }

      it "returns no errors" do
        put "/dois/#{doi.doi}", valid_attributes, headers

        expect(last_response.status).to eq(200)
        expect(json.dig("data", "attributes", "doi")).to eq(doi.doi)
      end
    end

    context "schema 2.2" do
      let(:xml) { Base64.strict_encode64(file_fixture("datacite_schema_2.2.xml").read) }
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "xml" => xml,
              "url" => "http://www.bl.uk/pdf/patspec.pdf",
              "event" => "publish",
            },
          },
        }
      end

      it "returns status code 422" do
        patch "/dois/10.14454/10703", valid_attributes, headers

        expect(last_response.status).to eq(422)
        expect(json.fetch("errors", nil)).to eq([{ "source" => "xml", "title" => "DOI 10.14454/10703: Schema http://datacite.org/schema/kernel-2.2 is no longer supported", "uid" => "10.14454/10703" }])
      end
    end

    context "NoMethodError https://github.com/datacite/lupo/issues/84" do
      let(:doi) { create(:doi, doi: "10.14454/4K3M-NYVG", client: client) }
      let(:url) { "https://figshare.com/articles/Additional_file_1_of_Contemporary_ancestor_Adaptive_divergence_from_standing_genetic_variation_in_Pacific_marine_threespine_stickleback/6839054/1" }
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "url" => url,
              "xml" => Base64.strict_encode64(doi.xml),
              "event" => "publish",
            },
          },
        }
      end

      it "returns no errors" do
        put "/dois/#{doi.doi}", valid_attributes, headers

        expect(last_response.status).to eq(200)
        expect(json.dig("data", "attributes", "doi")).to eq(doi.doi.downcase)
        expect(json.dig("data", "attributes", "url")).to eq(url)
      end
    end

    context "when the record doesn't exist" do
      let(:doi_id) { "10.14454/4K3M-NYVG" }
      let(:xml) { Base64.strict_encode64(file_fixture("datacite.xml").read) }
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "url" => "http://www.bl.uk/pdf/pat.pdf",
              "xml" => xml,
              "event" => "publish",
            },
          },
        }
      end

      it "creates the record" do
        put "/dois/#{doi_id}", valid_attributes, headers

        expect(last_response.status).to eq(201)
        expect(json.dig("data", "attributes", "url")).to eq("http://www.bl.uk/pdf/pat.pdf")
        expect(json.dig("data", "attributes", "doi")).to eq(doi_id.downcase)
        expect(json.dig("data", "attributes", "titles")).to eq([{ "title" => "Eating your own Dog Food" }])
        expect(json.dig("data", "attributes", "state")).to eq("findable")
      end
    end

    context "when the record doesn't exist no creators publish" do
      let(:doi_id) { "10.14454/077d-fj48" }
      let(:xml) { Base64.strict_encode64(file_fixture("datacite_missing_creator.xml").read) }
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "url" => "http://www.bl.uk/pdf/pat.pdf",
              "xml" => xml,
              "event" => "publish",
            },
          },
        }
      end

      it "returns error" do
        put "/dois/#{doi_id}", valid_attributes, headers

        expect(last_response.status).to eq(422)
        expect(json["errors"]).to eq([{ "source" => "creators", "title" => "DOI #{doi_id}: Missing child element(s). Expected is ( {http://datacite.org/schema/kernel-4}creator ). at line 4, column 0", "uid" => "10.14454/077d-fj48" }])
      end
    end

    # no difference whether creators is nil, or attribute missing (see previous test)
    context "when the record doesn't exist no creators publish with json" do
      let(:doi_id) { "10.14454/077d-fj48" }
      let(:xml) { Base64.strict_encode64(file_fixture("datacite_missing_creator.xml").read) }
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "url" => "http://www.bl.uk/pdf/pat.pdf",
              "creators" => nil,
              "xml" => xml,
              "event" => "publish",
            },
          },
        }
      end

      it "returns error" do
        put "/dois/#{doi_id}", valid_attributes, headers

        expect(last_response.status).to eq(422)
        expect(json["errors"]).to eq([{ "source" => "creators", "title" => "DOI 10.14454/077d-fj48: Missing child element(s). Expected is ( {http://datacite.org/schema/kernel-4}creator ). at line 4, column 0", "uid" => "10.14454/077d-fj48" }])
      end
    end

    context "when the record exists with conversion" do
      let(:xml) { Base64.strict_encode64(file_fixture("crossref.bib").read) }
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "url" => "http://www.bl.uk/pdf/pat.pdf",
              "xml" => xml,
            },
          },
        }
      end

      it "updates the record" do
        patch "/dois/#{doi.doi}", valid_attributes, headers

        expect(last_response.status).to eq(200)
        expect(json.dig("data", "attributes", "url")).to eq("http://www.bl.uk/pdf/pat.pdf")
        expect(json.dig("data", "attributes", "doi")).to eq(doi.doi.downcase)
        expect(json.dig("data", "attributes", "titles")).to eq([{ "title" => "Automated quantitative histology reveals vascular morphodynamics during Arabidopsis hypocotyl secondary growth" }])
      end

      it "sets state to registered" do
        patch "/dois/#{doi.doi}", valid_attributes, headers

        expect(json.dig("data", "attributes", "state")).to eq("draft")
      end
    end

    context "when the date issued is changed to :tba" do
      let(:xml) { Base64.strict_encode64(file_fixture("datacite.xml").read) }
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "url" => "http://www.bl.uk/pdf/pat.pdf",
              "xml" => xml,
              "dates" => {
                "date" => ":tba",
                "dateType" => "Issued",
              },
              "event" => "publish",
            },
          },
        }
      end

      it "updates the record" do
        patch "/dois/#{doi.doi}", valid_attributes, headers

        expect(last_response.status).to eq(200)
        expect(json.dig("data", "attributes", "url")).to eq("http://www.bl.uk/pdf/pat.pdf")
        expect(json.dig("data", "attributes", "doi")).to eq(doi.doi.downcase)
        expect(json.dig("data", "attributes", "dates")).to eq([{ "date" => ":tba", "dateType" => "Issued" }])
        expect(json.dig("data", "attributes", "state")).to eq("findable")
      end
    end

    context "when the title is changed" do
      let(:xml) { Base64.strict_encode64(file_fixture("datacite.xml").read) }
      let(:titles) { [{ "title" => "Submitted chemical data for InChIKey=YAPQBXQYLJRXSA-UHFFFAOYSA-N" }] }
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "url" => "http://www.bl.uk/pdf/pat.pdf",
              "xml" => xml,
              "titles" => titles,
              "event" => "publish",
            },
          },
        }
      end

      it "updates the record" do
        patch "/dois/#{doi.doi}", valid_attributes, headers

        expect(last_response.status).to eq(200)
        expect(json.dig("data", "attributes", "url")).to eq("http://www.bl.uk/pdf/pat.pdf")
        expect(json.dig("data", "attributes", "doi")).to eq(doi.doi.downcase)
        expect(json.dig("data", "attributes", "titles")).to eq(titles)
        expect(json.dig("data", "attributes", "state")).to eq("findable")
      end
    end

    context "when the title is changed wrong format" do
      let(:xml) { Base64.strict_encode64(file_fixture("datacite.xml").read) }
      let(:titles) { "Submitted chemical data for InChIKey=YAPQBXQYLJRXSA-UHFFFAOYSA-N" }
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "url" => "http://www.bl.uk/pdf/pat.pdf",
              "xml" => xml,
              "titles" => titles,
              "event" => "publish",
            },
          },
        }
      end

      it "error" do
        patch "/dois/#{doi.doi}", valid_attributes, headers

        expect(last_response.status).to eq(422)
        expect(json["errors"]).to eq([{ "source" => "titles", "title" => "Title 'Submitted chemical data for InChIKey=YAPQBXQYLJRXSA-UHFFFAOYSA-N' should be an object instead of a string.", "uid" => "10.14454/4k3m-nyvg" }])
      end
    end

    context "when the description is changed to empty" do
      let(:xml) { Base64.strict_encode64(file_fixture("datacite.xml").read) }
      let(:descriptions) { [] }
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "url" => "http://www.bl.uk/pdf/pat.pdf",
              "xml" => xml,
              "descriptions" => descriptions,
              "event" => "publish",
            },
          },
        }
      end

      it "updates the record" do
        patch "/dois/#{doi.doi}", valid_attributes, headers

        expect(last_response.status).to eq(200)
        expect(json.dig("data", "attributes", "url")).to eq("http://www.bl.uk/pdf/pat.pdf")
        expect(json.dig("data", "attributes", "doi")).to eq(doi.doi.downcase)
        expect(json.dig("data", "attributes", "descriptions")).to eq([])
        expect(json.dig("data", "attributes", "state")).to eq("findable")
      end
    end

    context "when the xml field has datacite_json" do
      let(:doi_id) { "10.14454/077d-fj48" }
      let(:xml) { Base64.strict_encode64(file_fixture("datacite-user-example.json").read) }
      let(:valid_attributes) do
        {
          "data" => {
            "id" => doi_id,
            "attributes" => {
              "doi" => doi_id,
              "xml" => xml,
              "event" => "publish",
            },
            "type" => "dois",
          },
        }
      end

      it "updates the record" do
        patch "/dois/#{doi.doi}", valid_attributes, headers

        expect(last_response.status).to eq(200)
        expect(json.dig("data", "attributes", "doi")).to eq(doi.doi.downcase)
        expect(json.dig("data", "attributes", "titles", 0, "title")).to eq("The Relationship Among Sport Type, Micronutrient Intake and Bone Mineral Density in an Athlete Population")
        expect(json.dig("data", "attributes", "descriptions", 0, "description")).to start_with("Diet and physical activity are two modifiable factors that can curtail the development of osteoporosis in the aging population. ")
        expect(json.dig("data", "attributes", "state")).to eq("findable")
      end
    end

    context "when a doi is created ignore reverting back" do
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
              "fundingReferences": [{
                "funderName": "fake_funder_name",
                "schemeUri": "http://funder_uri"
              }]
            },
          },
        }
      end
      let(:undo_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "doi" => doi.doi,
            }
          },
        }
      end

      it "creates the record" do
        post "/dois", valid_attributes, headers

        expect(last_response.status).to eq(201)
        expect(json.dig("data", "attributes", "titles")).to eq([{ "title" => "Eating your own Dog Food" }])
        expect(json.dig("data", "attributes", "fundingReferences").first["schemeUri"]).to eq("http://funder_uri")
      end

      it "revert the changes" do
        post "/dois", valid_attributes, headers

        expect(last_response.status).to eq(201)
        post "/dois/undo", undo_attributes, headers

        expect(last_response.status).to eq(200)
        expect(json.dig("data", "attributes", "titles")).to eq([{ "title" => "Data from: A new malaria agent in African hominids." }])
      end
    end

    context "when the title is changed and reverted back" do
      let(:xml) { Base64.strict_encode64(file_fixture("datacite.xml").read) }
      let(:titles) { [{ "title" => "Submitted chemical data for InChIKey=YAPQBXQYLJRXSA-UHFFFAOYSA-N" }] }
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "url" => "http://www.bl.uk/pdf/pat.pdf",
              "xml" => xml,
              "titles" => titles,
              "event" => "publish",
            },
          },
        }
      end
      let(:undo_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "doi" => doi.doi,
            },
          },
        }
      end

      it "updates the record" do
        patch "/dois/#{doi.doi}", valid_attributes, headers

        expect(last_response.status).to eq(200)
        expect(json.dig("data", "attributes", "titles")).to eq(titles)
      end

      it "revert the changes" do
        patch "/dois/#{doi.doi}", valid_attributes, headers

        expect(last_response.status).to eq(200)
        post "/dois/undo", undo_attributes, headers

        expect(last_response.status).to eq(200)
        expect(json.dig("data", "attributes", "titles")).to eq([{ "title" => "Data from: A new malaria agent in African hominids." }])
      end
    end

    context "when the creators change" do
      let(:xml) { Base64.strict_encode64(file_fixture("datacite.xml").read) }
      let(:creators) { [{ "affiliation" => [], "nameIdentifiers" => [], "name" => "Ollomi, Benjamin" }, { "affiliation" => [], "nameIdentifiers" => [], "name" => "Duran, Patrick" }] }
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "url" => "http://www.bl.uk/pdf/pat.pdf",
              "xml" => xml,
              "creators" => creators,
              "event" => "publish",
            },
          },
        }
      end

      it "updates the record" do
        patch "/dois/#{doi.doi}", valid_attributes, headers

        expect(last_response.status).to eq(200)
        expect(json.dig("data", "attributes", "url")).to eq("http://www.bl.uk/pdf/pat.pdf")
        expect(json.dig("data", "attributes", "doi")).to eq(doi.doi.downcase)
        expect(json.dig("data", "attributes", "creators")).to eq(creators)
        expect(json.dig("data", "attributes", "state")).to eq("findable")
      end
    end

    context "fail when we transfer a DOI as provider" do
      let(:provider_bearer) { User.generate_token(uid: "datacite", role_id: "provider_admin", name: "DataCite", email: "support@datacite.org", provider_id: "datacite") }
      let(:provider_headers) { { "HTTP_ACCEPT" => "application/vnd.api+json", "CONTENT_TYPE" => "application/vnd.api+json", "HTTP_AUTHORIZATION" => "Bearer " + provider_bearer } }

      let(:doi) { create(:doi, client: client) }
      let(:new_client) { create(:client, symbol: "#{provider.symbol}.magic", provider: provider, password: ENV["MDS_PASSWORD"]) }

      #  attributes MUST be empty
      let(:valid_attributes) { file_fixture("transfer.json").read }

      it "returns errors" do
        put "/dois/#{doi.doi}", valid_attributes.to_json, provider_headers

        expect(last_response.status).to eq(403)
      end
    end

    context "passes when we transfer a DOI as provider" do
      let(:provider_bearer) { User.generate_token(uid: "datacite", role_id: "provider_admin", name: "DataCite", email: "support@datacite.org", provider_id: "datacite") }
      let(:provider_headers) { { "HTTP_ACCEPT" => "application/vnd.api+json", "CONTENT_TYPE" => "application/vnd.api+json", "HTTP_AUTHORIZATION" => "Bearer " + provider_bearer } }

      let(:doi) { create(:doi, client: client) }
      let(:new_client) { create(:client, symbol: "#{provider.symbol}.M", provider: provider, password: ENV["MDS_PASSWORD"]) }

      #  attributes MUST be empty
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "mode" => "transfer",
            },
            "relationships" => {
              "client" => {
                "data" => {
                  "type" => "clients",
                  "id" => new_client.symbol.downcase,
                },
              },
            },
          },
        }
      end

      it "updates the client id" do
        put "/dois/#{doi.doi}", valid_attributes.to_json, provider_headers

        expect(last_response.status).to eq(200)
        expect(json.dig("data", "attributes", "doi")).to eq(doi.doi.downcase)
        expect(json.dig("data", "relationships", "client", "data", "id")).to eq(new_client.symbol.downcase)
        expect(json.dig("data", "attributes", "titles")).to eq(doi.titles)
      end
    end

    context "when we transfer a DOI as staff" do
      let(:doi) { create(:doi, doi: "10.14454/119495", url: "http://www.bl.uk/pdf/pat.pdf", client: client, aasm_state: "registered") }
      let(:new_client) { create(:client, symbol: "#{provider.symbol}.M", provider: provider, password: ENV["MDS_PASSWORD"]) }
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "mode" => "transfer",
            },
            "relationships" => {
              "client" => {
                "data" => {
                  "type" => "clients",
                  "id" => new_client.symbol.downcase,
                },
              },
            },
          },
        }
      end

      it "updates the client id" do
        put "/dois/#{doi.doi}", valid_attributes, admin_headers

        expect(last_response.status).to eq(200)
        expect(json.dig("data", "attributes", "doi")).to eq(doi.doi)
        expect(json.dig("data", "relationships", "client", "data", "id")).to eq(new_client.symbol.downcase)
      end
    end

    context "when we transfer a DOI as staff and the client has non-matching domains" do
      let(:doi) { create(:doi, doi: "10.14454/119495", url: "http://www.bl.uk/pdf/pat.pdf", client: client, aasm_state: "registered") }
      let(:new_client) { create(:client, symbol: "#{provider.symbol}.M", provider: provider, password: ENV["MDS_PASSWORD"], domains: "datacite.org") }
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "mode" => "transfer",
            },
            "relationships" => {
              "client" => {
                "data" => {
                  "type" => "clients",
                  "id" => new_client.symbol.downcase,
                },
              },
            },
          },
        }
      end

      it "updates the client id" do
        put "/dois/#{doi.doi}", valid_attributes, admin_headers

        expect(last_response.status).to eq(200)
        expect(json.dig("data", "attributes", "doi")).to eq(doi.doi)
        expect(json.dig("data", "relationships", "client", "data", "id")).to eq(new_client.symbol.downcase)
      end
    end

    context "when we transfer a DOI as staff and the DOI has a schema version that is not supported" do
      let(:doi) do
        d = build(:doi, doi: "10.14454/119495", schema_version: "http://datacite.org/schema/kernel-3", url: "http://www.bl.uk/pdf/pat.pdf", client: client, aasm_state: "registered")
        d.save(validate: false)
        d
      end
      let(:new_client) { create(:client, symbol: "#{provider.symbol}.M", provider: provider, password: ENV["MDS_PASSWORD"]) }
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "mode" => "transfer",
            },
            "relationships" => {
              "client" => {
                "data" => {
                  "type" => "clients",
                  "id" => new_client.symbol.downcase,
                },
              },
            },
          },
        }
      end

      it "updates the client id" do
        put "/dois/#{doi.doi}", valid_attributes, admin_headers

        expect(last_response.status).to eq(200)
        expect(json.dig("data", "attributes", "doi")).to eq(doi.doi)
        expect(json.dig("data", "relationships", "client", "data", "id")).to eq(new_client.symbol.downcase)
      end
    end

    context "when the resource_type_general changes" do
      let(:xml) { Base64.strict_encode64(file_fixture("datacite.xml").read) }
      let(:types) { { "resourceTypeGeneral" => "DataPaper", "resourceType" => "BlogPosting" } }
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "url" => "http://www.bl.uk/pdf/pat.pdf",
              "xml" => xml,
              "types" => types,
              "event" => "publish",
            },
          },
        }
      end

      it "updates the record" do
        patch "/dois/#{doi.doi}", valid_attributes, headers

        expect(last_response.status).to eq(200)
        expect(json.dig("data", "attributes", "url")).to eq("http://www.bl.uk/pdf/pat.pdf")
        expect(json.dig("data", "attributes", "doi")).to eq(doi.doi.downcase)
        expect(json.dig("data", "attributes", "types")).to eq("bibtex" => "article", "citeproc" => "", "resourceType" => "BlogPosting", "resourceTypeGeneral" => "DataPaper", "ris" => "GEN", "schemaOrg" => "Article")
        expect(json.dig("data", "attributes", "state")).to eq("findable")
      end
    end
  end

  context "when a doi has values in xml" do
    let(:valid_attributes) do
      {
        "data" => {
          "type" => "dois",
          "attributes" => {
            "subjects" => [],
            "identifiers" => [],
          },
        },
      }
    end

    it "the xml and doi record contain the values" do
      xml = Maremma.from_xml(doi.xml).fetch("resource", {})
      expect(xml.dig("subjects")).not_to eq(nil)
      expect(xml.dig("alternateIdentifiers")).not_to eq(nil)
      expect(doi.subjects).not_to eq(nil)
      expect(doi.identifiers).not_to eq(nil)
    end

    it "the values are removed when blank values are sent in json" do
      patch "/dois/#{doi.doi}", valid_attributes, headers

      xml = Maremma.from_xml(Base64.decode64(json.dig("data", "attributes", "xml"))).fetch("resource", {})
      expect(xml.dig("subjects")).to eq(nil)
      expect(xml.dig("alternateIdentifiers")).to eq(nil)
      expect(json.dig("data", "attributes", "subjects")).to eq([])
      expect(json.dig("data", "attributes", "identifiers")).to eq([])
      expect(json.dig("data", "attributes", "alternateIdentifiers")).to eq([])
    end
  end

  context "when a doi has values in xml" do
    let(:valid_attributes) do
      {
        "data" => {
          "type" => "dois",
          "attributes" => {
            "subjects" => nil,
          },
        },
      }
    end

    it "the xml and doi record contain the values" do
      xml = Maremma.from_xml(doi.xml).fetch("resource", {})
      expect(xml.dig("subjects")).not_to eq(nil)
      expect(doi.subjects).not_to eq(nil)
    end

    it "the values are removed when null values are sent in json" do
      patch "/dois/#{doi.doi}", valid_attributes, headers

      xml = Maremma.from_xml(Base64.decode64(json.dig("data", "attributes", "xml"))).fetch("resource", {})
      expect(xml.dig("subjects")).to eq(nil)
      expect(json.dig("data", "attributes", "subjects")).to eq([])
    end
  end

  context "when a doi has alternateIdentifier/identifier values" do
    let(:valid_attributes) do
      {
        "data" => {
          "type" => "dois",
          "attributes" => {
            "alternateIdentifiers" => nil,
          },
        },
      }
    end

    it "the xml and doi record contain the values" do
      xml = Maremma.from_xml(doi.xml).fetch("resource", {})
      expect(xml.dig("alternateIdentifiers")).not_to eq(nil)
      expect(doi.identifiers).not_to eq(nil)
    end

    it "the values are removed when nil values are sent in json" do
      patch "/dois/#{doi.doi}", valid_attributes, headers

      xml = Maremma.from_xml(Base64.decode64(json.dig("data", "attributes", "xml"))).fetch("resource", {})
      expect(xml.dig("alternateIdentifiers")).to eq(nil)
      expect(json.dig("data", "attributes", "identifiers")).to eq([])
      expect(json.dig("data", "attributes", "alternateIdentifiers")).to eq([])
    end
  end

  context "when a doi has alternateIdentifier/identifier values" do
    let(:valid_attributes) do
      {
        "data" => {
          "type" => "dois",
          "attributes" => {
            "alternateIdentifiers" => [],
          },
        },
      }
    end

    it "the xml and doi record contain the values" do
      xml = Maremma.from_xml(doi.xml).fetch("resource", {})
      expect(xml.dig("alternateIdentifiers")).not_to eq(nil)
      expect(doi.identifiers).not_to eq(nil)
    end

    it "the values are removed when blank values are sent in json" do
      patch "/dois/#{doi.doi}", valid_attributes, headers

      xml = Maremma.from_xml(Base64.decode64(json.dig("data", "attributes", "xml"))).fetch("resource", {})
      expect(xml.dig("alternateIdentifiers")).to eq(nil)
      expect(json.dig("data", "attributes", "identifiers")).to eq([])
      expect(json.dig("data", "attributes", "alternateIdentifiers")).to eq([])
    end
  end

  context "when a doi has alternateIdentifier/identifier values" do
    let(:valid_attributes) do
      {
        "data" => {
          "type" => "dois",
          "attributes" => {
            "alternateIdentifiers" => [
              {
                "alternateIdentifier" => "identifier",
                "alternateIdentifierType" => "identifierType",
              },
              {
                "alternateIdentifier" => "identifier_2",
                "alternateIdentifierType" => "identifierType_2",
              },
            ],
          },
        },
      }
    end

    it "the xml and doi record contain the values" do
      xml = Maremma.from_xml(doi.xml).fetch("resource", {})
      expect(xml.dig("alternateIdentifiers")).not_to eq(nil)
      expect(doi.identifiers).not_to eq(nil)
    end

    it "the values are changed when new values are sent in json" do
      patch "/dois/#{doi.doi}", valid_attributes, headers

      xml = Maremma.from_xml(Base64.decode64(json.dig("data", "attributes", "xml"))).fetch("resource", {})
      expect(xml.dig("alternateIdentifiers")).to eq(
        "alternateIdentifier" =>
          [
            { "__content__" => "identifier", "alternateIdentifierType" => "identifierType" },
            { "__content__" => "identifier_2", "alternateIdentifierType" => "identifierType_2" }
          ]
      )
      expect(json.dig("data", "attributes", "identifiers")).to eq([
        {
          "identifier" => "identifier",
          "identifierType" => "identifierType"
        },
        {
          "identifier" => "identifier_2",
          "identifierType" => "identifierType_2"
        }
      ])
      expect(json.dig("data", "attributes", "alternateIdentifiers")).to eq([
        {
          "alternateIdentifier" => "identifier",
          "alternateIdentifierType" => "identifierType"
        },
        {
          "alternateIdentifier" => "identifier_2",
          "alternateIdentifierType" => "identifierType_2"
        }
      ])
    end

    context "when a doi has alternateIdentifier/identifier values" do
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "subjects" => nil,
            },
          },
        }
      end

      it "the xml and doi record contain the values" do
        xml = Maremma.from_xml(doi.xml).fetch("resource", {})
        expect(xml.dig("alternateIdentifiers")).not_to eq(nil)
        expect(doi.identifiers).not_to eq(nil)
      end

      it "the values are the same when no values are sent in json" do
        patch "/dois/#{doi.doi}", valid_attributes, headers

        xml = Maremma.from_xml(Base64.decode64(json.dig("data", "attributes", "xml"))).fetch("resource", {})
        expect(xml.dig("alternateIdentifiers")).to eq(
          "alternateIdentifier" => {
            "__content__" => "pk-1234", "alternateIdentifierType" => "publisher ID"
          }
        )
        expect(json.dig("data", "attributes", "identifiers")).to eq([
          {
            "identifier" => "pk-1234",
            "identifierType" => "publisher ID"
          },
        ])
        expect(json.dig("data", "attributes", "alternateIdentifiers")).to eq([
          {
            "alternateIdentifier" => "pk-1234",
            "alternateIdentifierType" => "publisher ID"
          },
        ])
      end
    end
  end

  # Metadata 4.7 - elements

  context "when the record exists" do
    let(:xml) { Base64.strict_encode64(file_fixture("datacite-example-full-v4.7.xml").read) }
    let(:valid_attributes) do
      {
        "data" => {
          "type" => "dois",
          "attributes" => {
            "url" => "http://www.bl.uk/pdf/pat.pdf",
            "xml" => xml,
          },
        },
      }
    end

    it "updates the record" do
      patch "/dois/#{doi.doi}", valid_attributes, headers

      expect(last_response.status).to eq(200)

      expect(json.dig("data", "attributes", "url")).to eq("http://www.bl.uk/pdf/pat.pdf")
      expect(json.dig("data", "attributes", "doi")).to eq(doi.doi.downcase)
      
      expect(json.dig("data", "attributes", "types", "resourceTypeGeneral")).to eq("Presentation")
      expect(json.dig("data", "attributes", "types", "resourceType")).to eq("Example ResourceType")

      expect(json.dig("data", "attributes", "relatedIdentifiers", 40, "relationType")).to eq("Other")
      expect(json.dig("data", "attributes", "relatedIdentifiers", 40, "relationTypeInformation")).to eq("More relationType information to supplement relationType 'Other'")

      expect(json.dig("data", "attributes", "relatedItems", 3, "relatedItemType")).to eq("Presentation")
      expect(json.dig("data", "attributes", "relatedItems", 4, "relatedItemType")).to eq("Poster")
      expect(json.dig("data", "attributes", "relatedItems", 5, "relatedItemIdentifier", "relatedItemIdentifierType")).to eq("SWHID")
      expect(json.dig("data", "attributes", "relatedItems", 6, "relationType")).to eq("Other")
      # expect(json.dig("data", "attributes", "relatedItems", 6, "relationTypeInformation")).to eq("More relationType information to supplement relationType 'Other'")
    end
  end
end
