# frozen_string_literal: true

require "rails_helper"
include Passwordable
require "pp"

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

    context "when the request is valid no password" do
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

      it "fails to create a Doi" do
        post "/dois", valid_attributes

        expect(last_response.status).to eq(401)
      end
    end

    context "when the request has invalid client domains" do
      let(:client) { create(:client, provider: provider, symbol: ENV["MDS_USERNAME"], password: ENV["MDS_PASSWORD"], re3data_id: "10.17616/r3xs37", domains: "example.org") }
      let(:bearer) { Client.generate_token(role_id: "client_admin", uid: client.symbol, provider_id: provider.symbol.downcase, client_id: client.symbol.downcase, password: client.password) }
      let(:headers) { { "HTTP_ACCEPT" => "application/vnd.api+json", "HTTP_AUTHORIZATION" => "Bearer " + bearer } }
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

      it "fails to create a Doi" do
        post "/dois", valid_attributes, headers

        expect(last_response.status).to eq(422)
        expect(json.dig("errors", 0, "title")).to end_with("is not allowed by repository #{doi.client.uid} domain settings.")
      end
    end

    context "when providing version" do
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "doi" => "10.14454/10703",
              "url" => "http://www.bl.uk/pdf/patspec.pdf",
              # "xml" => xml,
              "source" => "test",
              "version" => 45,
            },
          },
        }
      end

      it "create a draft Doi with version" do
        post "/dois", valid_attributes, headers

        expect(last_response.status).to eq(201)
        expect(json.dig("data", "attributes", "version")).to eq("45")
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

    context "when the request is valid with attributes" do
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "doi" => "10.14454/10703",
              "url" => "http://www.bl.uk/pdf/patspec.pdf",
              "types" => { "bibtex" => "article", "citeproc" => "article-journal", "resourceType" => "BlogPosting", "resourceTypeGeneral" => "Text", "ris" => "RPRT", "schemaOrg" => "ScholarlyArticle" },
              "titles" => [{ "title" => "Eating your own Dog Food" }],
              "publisher" => "DataCite",
              "publicationYear" => 2016,
              "creators" => [{ "familyName" => "Fenner", "givenName" => "Martin", "nameIdentifiers" => [{ "nameIdentifier" => "https://orcid.org/0000-0003-1419-2405", "nameIdentifierScheme" => "ORCID", "schemeUri" => "https://orcid.org" }], "name" => "Fenner, Martin", "nameType" => "Personal" }],
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
        expect(json.dig("data", "attributes", "creators")).to eq([{ "affiliation" => [], "familyName" => "Fenner", "givenName" => "Martin", "nameIdentifiers" => [{ "nameIdentifier" => "https://orcid.org/0000-0003-1419-2405", "nameIdentifierScheme" => "ORCID", "schemeUri" => "https://orcid.org" }], "name" => "Fenner, Martin", "nameType" => "Personal" }])
        expect(json.dig("data", "attributes", "publisher")).to eq("DataCite")
        expect(json.dig("data", "attributes", "publicationYear")).to eq(2016)
        # expect(json.dig('data', 'attributes', 'schemaVersion')).to eq("http://datacite.org/schema/kernel-4")
        expect(json.dig("data", "attributes", "source")).to eq("test")
        expect(json.dig("data", "attributes", "types")).to eq("bibtex" => "article", "citeproc" => "article-journal", "resourceType" => "BlogPosting", "resourceTypeGeneral" => "Text", "ris" => "RPRT", "schemaOrg" => "ScholarlyArticle")
        expect(json.dig("data", "attributes", "state")).to eq("findable")

        doc = Nokogiri::XML(Base64.decode64(json.dig("data", "attributes", "xml")), nil, "UTF-8", &:noblanks)
        expect(doc.at_css("identifier").content).to eq("10.14454/10703")

        expect(Doi.where(doi: "10.14454/10703").first.publisher).to eq(
          {
            "name" => "DataCite"
          }
        )
      end
    end

    context "when the request is valid with recommended properties" do
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "doi" => "10.14454/10703",
              "url" => "http://www.bl.uk/pdf/patspec.pdf",
              "types" => { "bibtex" => "article", "citeproc" => "article-journal", "resourceType" => "BlogPosting", "resourceTypeGeneral" => "Text", "ris" => "RPRT", "schemaOrg" => "ScholarlyArticle" },
              "titles" => [{ "title" => "Eating your own Dog Food" }],
              "publisher" => "DataCite",
              "publicationYear" => 2016,
              "creators" => [{ "familyName" => "Fenner", "givenName" => "Martin", "nameIdentifiers" => [{ "nameIdentifier" => "https://orcid.org/0000-0003-1419-2405", "nameIdentifierScheme" => "ORCID", "schemeUri" => "https://orcid.org" }], "name" => "Fenner, Martin", "nameType" => "Personal" }],
              "subjects" => [{ "subject" => "80505 Web Technologies (excl. Web Search)",
                               "schemeUri" => "http://www.abs.gov.au/ausstats/abs@.nsf/0/6BB427AB9696C225CA2574180004463E",
                               "subjectScheme" => "FOR",
                               "lang" => "en",
                               "classificationCode" => "080505" }],
              "contributors" => [{ "contributorType" => "DataManager", "familyName" => "Fenner", "givenName" => "Kurt", "nameIdentifiers" => [{ "nameIdentifier" => "https://orcid.org/0000-0003-1419-2401", "nameIdentifierScheme" => "ORCID", "schemeUri" => "https://orcid.org" }], "name" => "Fenner, Kurt", "nameType" => "Personal" }],
              "dates" => [{ "date" => "2017-02-24", "dateType" => "Issued" }, { "date" => "2015-11-28", "dateType" => "Created" }, { "date" => "2017-02-24", "dateType" => "Updated" }],
              "relatedIdentifiers" => [{ "relatedIdentifier" => "10.5438/55e5-t5c0", "relatedIdentifierType" => "DOI", "relationType" => "References" }],
              "descriptions" => [
                {
                  "lang" => "en",
                  "description" => "Diet and physical activity are two modifiable factors that can curtail the development of osteoporosis in the aging population. One purpose of this study was to assess the differences in dietary intake and bone mineral density (BMD) in a Masters athlete population (n=87, n=49 female; 41.06 ± 5.00 years of age) and examine sex- and sport-related differences in dietary and total calcium and vitamin K intake and BMD of the total body, lumbar spine, and dual femoral neck (TBBMD, LSBMD and DFBMD, respectively). Total calcium is defined as calcium intake from diet and supplements. Athletes were categorized as participating in an endurance or interval sport. BMD was measured using dual-energy X-ray absorptiometry (DXA). Data on dietary intake was collected from Block 2005 Food Frequency Questionnaires (FFQs). Dietary calcium, total calcium, or vitamin K intake did not differ between the female endurance and interval athletes. All three BMD sites were significantly different among the female endurance and interval athletes, with female interval athletes having higher BMD at each site (TBBMD: 1.26 ± 0.10 g/cm2, p<0.05; LSBMD: 1.37 ± 0.14 g/cm2, p<0.01; DFBMD: 1.11 ± 0.12 g/cm2, p<0.05, for female interval athletes; TBBMD: 1.19 ± 0.09 g/cm2; LSBMD: 1.23 ± 0.16 g/cm2; DFBMD: 1.04 ± 0.10 g/cm2, for female endurance athletes). Male interval athletes had higher BMD at all three sites (TBBMD 1.44 ± 0.11 g/cm2, p<0.05; LSBMD 1.42 ± 0.15 g/cm2, p=0.179; DFBMD 1.26 ± 0.14 g/cm2, p<0.01, for male interval athletes; TBBMD 1.33 ± 0.11 g/cm2; LSBMD 1.33 ± 0.17 g/cm2; DFBMD 1.10 ± 0.12 g/cm2 for male endurance athletes). Dietary calcium, total daily calcium and vitamin K intake did not differ between the male endurance and interval athletes. This study evaluated the relationship between calcium intake and BMD. No relationship between dietary or total calcium intake and BMD was evident in all female athletes, female endurance athletes or female interval athletes. In all male athletes, there was no significant correlation between dietary or total calcium intake and BMD at any of the measured sites. However, the male interval athlete group had a negative relationship between dietary calcium intake and TBBMD (r=-0.738, p<0.05) and LSBMD (r=-0.738, p<0.05). The negative relationship persisted between total calcium intake and LSBMD (r=-0.714, p<0.05), but not TBBMD, when calcium from supplements was included. The third purpose of this study was to evaluate the relationship between vitamin K intake (as phylloquinone) and BMD. In all female athletes, there was no significant correlation between vitamin K intake and BMD at any of the measured sites. No relationship between vitamin K and BMD was evident in female interval or female endurance athletes. Similarly, there was no relationship between vitamin K intake and BMD in the male endurance and interval groups. The final purpose of this study was to assess the relationship between the Calcium-to-Vitamin K (Ca:K) ratio and BMD. A linear regression model established that the ratio predicted TBBMD in female athletes, F(1,47) = 4.652, p <0.05, and the ratio accounted for 9% of the variability in TBBMD. The regression equation was: predicted TBBMD in a female athlete = 1.250 - 0.008 x (Ca:K). In conclusion, Masters interval athletes have higher BMD than Masters endurance athletes; however, neither dietary or supplemental calcium nor vitamin K were related to BMD in skeletal sites prone to fracture in older adulthood. We found that a Ca:K ratio could predict TBBMD in female athletes. Further research should consider the calcium-to-vitamin K relationship in conjunction with other modifiable, lifestyle factors associated with bone health in the investigation of methods to minimize the development and effect of osteoporosis in the older athlete population.",
                  "descriptionType" => "Abstract",
                },
              ],
              "geoLocations" => [
                {
                  "geoLocationPoint" => {
                    "pointLatitude" => 49.0850736,
                    "pointLongitude" => -123.3300992,
                  },
                },
              ],
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
        expect(json.dig("data", "attributes", "creators")).to eq([{ "affiliation" => [], "familyName" => "Fenner", "givenName" => "Martin", "nameIdentifiers" => [{ "nameIdentifier" => "https://orcid.org/0000-0003-1419-2405", "nameIdentifierScheme" => "ORCID", "schemeUri" => "https://orcid.org" }], "name" => "Fenner, Martin", "nameType" => "Personal" }])
        expect(json.dig("data", "attributes", "publisher")).to eq("DataCite")
        expect(json.dig("data", "attributes", "publicationYear")).to eq(2016)
        expect(json.dig("data", "attributes", "subjects")).to eq([{ "lang" => "en",
                                                                    "subject" => "80505 Web Technologies (excl. Web Search)",
                                                                    "schemeUri" => "http://www.abs.gov.au/ausstats/abs@.nsf/0/6BB427AB9696C225CA2574180004463E",
                                                                    "subjectScheme" => "FOR",
                                                                    "classificationCode" => "080505" },
                                                                  { "schemeUri" => "http://www.oecd.org/science/inno/38235147.pdf",
                                                                    "subject" => "FOS: Computer and information sciences",
                                                                    "subjectScheme" => "Fields of Science and Technology (FOS)" }
                                                                  ])
        expect(json.dig("data", "attributes", "contributors")).to eq([{ "affiliation" => [],
                                                                        "contributorType" => "DataManager",
                                                                        "familyName" => "Fenner",
                                                                        "givenName" => "Kurt",
                                                                        "name" => "Fenner, Kurt",
                                                                        "nameIdentifiers" =>
            [{ "nameIdentifier" => "https://orcid.org/0000-0003-1419-2401",
               "nameIdentifierScheme" => "ORCID",
               "schemeUri" => "https://orcid.org" }],
                                                                        "nameType" => "Personal" }])
        expect(json.dig("data", "attributes", "dates")).to eq([{ "date" => "2017-02-24", "dateType" => "Issued" }, { "date" => "2015-11-28", "dateType" => "Created" }, { "date" => "2017-02-24", "dateType" => "Updated" }])
        expect(json.dig("data", "attributes", "relatedIdentifiers")).to eq([{ "relatedIdentifier" => "10.5438/55e5-t5c0", "relatedIdentifierType" => "DOI", "relationType" => "References" }])
        expect(json.dig("data", "attributes", "descriptions", 0, "description")).to start_with("Diet and physical activity")
        expect(json.dig("data", "attributes", "geoLocations")).to eq([{ "geoLocationPoint" => { "pointLatitude" => 49.0850736, "pointLongitude" => -123.3300992 } }])
        expect(json.dig("data", "attributes", "source")).to eq("test")
        expect(json.dig("data", "attributes", "types")).to eq("bibtex" => "article", "citeproc" => "article-journal", "resourceType" => "BlogPosting", "resourceTypeGeneral" => "Text", "ris" => "RPRT", "schemaOrg" => "ScholarlyArticle")
        expect(json.dig("data", "attributes", "state")).to eq("findable")

        doc = Nokogiri::XML(Base64.decode64(json.dig("data", "attributes", "xml")), nil, "UTF-8", &:noblanks)
        expect(doc.at_css("identifier").content).to eq("10.14454/10703")
        expect(doc.at_css("subjects").content).to eq("80505 Web Technologies (excl. Web Search)")
        expect(doc.at_css("contributors").content).to eq("Fenner, KurtKurtFennerhttps://orcid.org/0000-0003-1419-2401")
        expect(doc.at_css("dates").content).to eq("2017-02-242015-11-282017-02-24")
        expect(doc.at_css("relatedIdentifiers").content).to eq("10.5438/55e5-t5c0")
        expect(doc.at_css("descriptions").content).to start_with("Diet and physical activity")
        expect(doc.at_css("geoLocations").content).to eq("49.0850736-123.3300992")
      end
    end

    context "when the request is valid with optional properties" do
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "doi" => "10.14454/10703",
              "url" => "http://www.bl.uk/pdf/patspec.pdf",
              "types" => { "bibtex" => "article", "citeproc" => "article-journal", "resourceType" => "BlogPosting", "resourceTypeGeneral" => "Text", "ris" => "RPRT", "schemaOrg" => "ScholarlyArticle" },
              "titles" => [{ "title" => "Eating your own Dog Food" }],
              "publisher" => "DataCite",
              "publicationYear" => 2016,
              "creators" => [{ "familyName" => "Fenner", "givenName" => "Martin", "nameIdentifiers" => [{ "nameIdentifier" => "https://orcid.org/0000-0003-1419-2405", "nameIdentifierScheme" => "ORCID", "schemeUri" => "https://orcid.org" }], "name" => "Fenner, Martin", "nameType" => "Personal" }],
              "language" => "en",
              "alternateIdentifiers" => [{ "alternateIdentifier" => "123", "alternateIdentifierType" => "Repository ID" }],
              "rightsList" => [{ "rights" => "Creative Commons Attribution 3.0", "rightsUri" => "http://creativecommons.org/licenses/by/3.0/", "lang" => "en" }],
              "sizes" => ["4 kB", "12.6 MB"],
              "formats" => ["application/pdf", "text/csv"],
              "version" => "1.1",
              "fundingReferences" => [{ "funderIdentifier" => "https://doi.org/10.13039/501100009053", "funderIdentifierType" => "Crossref Funder ID", "funderName" => "The Wellcome Trust DBT India Alliance" }],
              "source" => "test",
              "event" => "publish",
              "relatedItems" => [{
                "contributors" => [{ "name" => "Smithson, James",
                                     "contributorType" => "ProjectLeader",
                                     "givenName" => "James",
                                     "familyName" => "Smithson",
                                     "nameType" => "Personal"
                                    }],
                "creators" => [{ "name" => "Smith, John",
                                 "nameType" => "Personal",
                                 "givenName" => "John",
                                 "familyName" => "Smith",
                                }],
                "firstPage" => "249",
                "lastPage" => "264",
                "publicationYear" => "2018",
                "relatedItemIdentifier" => { "relatedItemIdentifier" => "10.1016/j.physletb.2017.11.044",
                                             "relatedItemIdentifierType" => "DOI",
                                             "relatedMetadataScheme" => "citeproc+json",
                                             "schemeURI" => "https://github.com/citation-style-language/schema/raw/master/csl-data.json",
                                             "schemeType" => "URL"
                                            },
                "relatedItemType" => "Journal",
                "relationType" => "HasMetadata",
                "titles" => [{ "title" => "Physics letters / B" }],
                "volume" => "776"
              }],
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
        expect(json.dig("data", "attributes", "creators")).to eq([{ "affiliation" => [], "familyName" => "Fenner", "givenName" => "Martin", "nameIdentifiers" => [{ "nameIdentifier" => "https://orcid.org/0000-0003-1419-2405", "nameIdentifierScheme" => "ORCID", "schemeUri" => "https://orcid.org" }], "name" => "Fenner, Martin", "nameType" => "Personal" }])
        expect(json.dig("data", "attributes", "publisher")).to eq("DataCite")
        expect(json.dig("data", "attributes", "publicationYear")).to eq(2016)
        # expect(json.dig('data', 'attributes', 'schemaVersion')).to eq("http://datacite.org/schema/kernel-4")
        expect(json.dig("data", "attributes", "language")).to eq("en")
        expect(json.dig("data", "attributes", "identifiers")).to eq([{ "identifier" => "123", "identifierType" => "Repository ID" }])
        expect(json.dig("data", "attributes", "alternateIdentifiers")).to eq([{ "alternateIdentifier" => "123", "alternateIdentifierType" => "Repository ID" }])
        expect(json.dig("data", "attributes", "rightsList")).to eq([{ "lang" => "en", "rights" => "Creative Commons Attribution 3.0", "rightsUri" => "http://creativecommons.org/licenses/by/3.0/" }])
        expect(json.dig("data", "attributes", "sizes")).to eq(["4 kB", "12.6 MB"])
        expect(json.dig("data", "attributes", "formats")).to eq(["application/pdf", "text/csv"])
        expect(json.dig("data", "attributes", "version")).to eq("1.1")
        expect(json.dig("data", "attributes", "fundingReferences")).to eq([{ "funderIdentifier" => "https://doi.org/10.13039/501100009053", "funderIdentifierType" => "Crossref Funder ID", "funderName" => "The Wellcome Trust DBT India Alliance" }])
        expect(json.dig("data", "attributes", "source")).to eq("test")
        expect(json.dig("data", "attributes", "types")).to eq("bibtex" => "article", "citeproc" => "article-journal", "resourceType" => "BlogPosting", "resourceTypeGeneral" => "Text", "ris" => "RPRT", "schemaOrg" => "ScholarlyArticle")
        expect(json.dig("data", "attributes", "state")).to eq("findable")
        expect(json.dig("data", "attributes", "relatedItems")).to eq(["relationType" => "HasMetadata",
                                                                      "relatedItemType" => "Journal",
                                                                      "publicationYear" => "2018",
                                                                      "relatedItemIdentifier" => {
                                                                                                   "relatedItemIdentifier" => "10.1016/j.physletb.2017.11.044",
                                                                                                   "relatedItemIdentifierType" => "DOI",
                                                                                                   "relatedMetadataScheme" => "citeproc+json",
                                                                                                   "schemeURI" => "https://github.com/citation-style-language/schema/raw/master/csl-data.json",
                                                                                                   "schemeType" => "URL"
                                                                                                  },
                                                                      "contributors" => [{ "name" => "Smithson, James",
                                                                                           "contributorType" => "ProjectLeader",
                                                                                           "givenName" => "James",
                                                                                           "familyName" => "Smithson",
                                                                                           "nameType" => "Personal"
                                                                                          }],
                                                                      "creators" => [{ "name" => "Smith, John",
                                                                                       "nameType" => "Personal",
                                                                                       "givenName" => "John",
                                                                                       "familyName" => "Smith",
                                                                                      }],
                                                                      "firstPage" => "249",
                                                                      "lastPage" => "264",
                                                                      "titles" => [{ "title" => "Physics letters / B" }],
                                                                      "volume" => "776"
                                                                      ])

        doc = Nokogiri::XML(Base64.decode64(json.dig("data", "attributes", "xml")), nil, "UTF-8", &:noblanks)
        expect(doc.at_css("identifier").content).to eq("10.14454/10703")
        expect(doc.at_css("language").content).to eq("en")
        expect(doc.at_css("alternateIdentifiers").content).to eq("123")
        expect(doc.at_css("rightsList").content).to eq("Creative Commons Attribution 3.0")
        expect(doc.at_css("sizes").content).to eq("4 kB12.6 MB")
        expect(doc.at_css("formats").content).to eq("application/pdftext/csv")
        expect(doc.at_css("version").content).to eq("1.1")
        expect(doc.at_css("fundingReferences").content).to eq("The Wellcome Trust DBT India Alliancehttps://doi.org/10.13039/501100009053")
      end
    end

    context "with xml containing alternateIdentifiers" do
      let(:xml) { ::Base64.strict_encode64(File.read(file_fixture("datacite-example-affiliation.xml"))) }
      let(:params) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "doi" => "10.14454/10703",
              "xml" => xml
            },
          },
        }
      end

      it "validates a Doi" do
        post "/dois", params, headers

        expect(last_response.status).to eq(201)
        expect(json.dig("data", "attributes", "titles")).to eq([{ "lang" => "en-US", "title" => "Full DataCite XML Example" }, { "lang" => "en-US", "title" => "Demonstration of DataCite Properties.", "titleType" => "Subtitle" }])
        expect(json.dig("data", "attributes", "identifiers")).to eq([{ "identifier" => "https://schema.datacite.org/meta/kernel-4.2/example/datacite-example-full-v4.2.xml", "identifierType" => "URL" }])
        expect(json.dig("data", "attributes", "alternateIdentifiers")).to eq([{ "alternateIdentifier" => "https://schema.datacite.org/meta/kernel-4.2/example/datacite-example-full-v4.2.xml", "alternateIdentifierType" => "URL" }])

        doc = Nokogiri::XML(Base64.decode64(json.dig("data", "attributes", "xml")), nil, "UTF-8", &:noblanks)
        expect(doc.at_css("identifier").content).to eq("10.14454/10703")
        expect(doc.at_css("alternateIdentifiers").content).to eq("https://schema.datacite.org/meta/kernel-4.2/example/datacite-example-full-v4.2.xml")
      end
    end

    context "with affiliation" do
      let(:xml) { ::Base64.strict_encode64(File.read(file_fixture("datacite-example-affiliation.xml"))) }
      let(:params) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "doi" => "10.14454/10703",
              "xml" => xml,
            },
          },
        }
      end

      it "validates a Doi" do
        post "/dois", params, headers

        expect(last_response.status).to eq(201)
        expect(json.dig("data", "attributes", "titles")).to eq([{ "lang" => "en-US", "title" => "Full DataCite XML Example" }, { "lang" => "en-US", "title" => "Demonstration of DataCite Properties.", "titleType" => "Subtitle" }])
        expect(json.dig("data", "attributes", "creators").length).to eq(3)
        expect(json.dig("data", "attributes", "creators")[0]).to eq("affiliation" => ["DataCite"],
                                                                    "familyName" => "Miller",
                                                                    "givenName" => "Elizabeth",
                                                                    "name" => "Miller, Elizabeth",
                                                                    "nameIdentifiers" => [{ "nameIdentifier" => "https://orcid.org/0000-0001-5000-0007", "nameIdentifierScheme" => "ORCID", "schemeUri" => "https://orcid.org" }],
                                                                    "nameType" => "Personal")
        expect(json.dig("data", "attributes", "creators")[1]).to eq("affiliation" => ["Brown University", "Wesleyan University"],
                                                                    "familyName" => "Carberry",
                                                                    "givenName" => "Josiah",
                                                                    "name" => "Carberry, Josiah",
                                                                    "nameIdentifiers" => [{ "nameIdentifier" => "https://orcid.org/0000-0002-1825-0097", "nameIdentifierScheme" => "ORCID", "schemeUri" => "https://orcid.org" }],
                                                                    "nameType" => "Personal")
        expect(json.dig("data", "attributes", "creators")[2]).to eq("nameType" => "Organizational", "name" => "The Psychoceramics Study Group", "affiliation" => ["Brown University"], "nameIdentifiers" => [])

        xml = Maremma.from_xml(Base64.decode64(json.dig("data", "attributes", "xml"))).fetch("resource", {})
        expect(xml.dig("creators", "creator")[0]).to eq("affiliation" => { "__content__" => "DataCite", "affiliationIdentifier" => "https://ror.org/04wxnsj81", "affiliationIdentifierScheme" => "ROR" },
                                                        "creatorName" => { "__content__" => "Miller, Elizabeth", "nameType" => "Personal" },
                                                        "familyName" => "Miller",
                                                        "givenName" => "Elizabeth",
                                                        "nameIdentifier" => { "__content__" => "0000-0001-5000-0007", "nameIdentifierScheme" => "ORCID", "schemeURI" => "http://orcid.org/" })
      end
    end

    context "with affiliation and query parameter" do
      let(:xml) { ::Base64.strict_encode64(File.read(file_fixture("datacite-example-affiliation.xml"))) }
      let(:params) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "doi" => "10.14454/10703",
              "xml" => xml,
            },
          },
        }
      end

      it "validates a Doi" do
        post "/dois?affiliation=true", params, headers

        expect(last_response.status).to eq(201)
        expect(json.dig("data", "attributes", "titles")).to eq([{ "lang" => "en-US", "title" => "Full DataCite XML Example" }, { "lang" => "en-US", "title" => "Demonstration of DataCite Properties.", "titleType" => "Subtitle" }])
        expect(json.dig("data", "attributes", "creators").length).to eq(3)
        expect(json.dig("data", "attributes", "creators")[0]).to eq("affiliation" => [{ "affiliationIdentifierScheme" => "ROR", "affiliationIdentifier" => "https://ror.org/04wxnsj81", "name" => "DataCite" }],
                                                                    "familyName" => "Miller",
                                                                    "givenName" => "Elizabeth",
                                                                    "name" => "Miller, Elizabeth",
                                                                    "nameIdentifiers" => [{ "nameIdentifier" => "https://orcid.org/0000-0001-5000-0007", "nameIdentifierScheme" => "ORCID", "schemeUri" => "https://orcid.org" }],
                                                                    "nameType" => "Personal")
        expect(json.dig("data", "attributes", "creators")[1]).to eq("affiliation" => [{ "affiliationIdentifierScheme" => "ROR", "affiliationIdentifier" => "https://ror.org/05gq02987", "name" => "Brown University" }, { "affiliationIdentifierScheme" => "GRID", "affiliationIdentifier" => "https://grid.ac/institutes/grid.268117.b", "schemeUri" => "https://grid.ac/institutes/", "name" => "Wesleyan University" }],
                                                                    "familyName" => "Carberry",
                                                                    "givenName" => "Josiah",
                                                                    "name" => "Carberry, Josiah",
                                                                    "nameIdentifiers" => [{ "nameIdentifier" => "https://orcid.org/0000-0002-1825-0097", "nameIdentifierScheme" => "ORCID", "schemeUri" => "https://orcid.org" }],
                                                                    "nameType" => "Personal")
        expect(json.dig("data", "attributes", "creators")[2]).to eq("nameType" => "Organizational", "name" => "The Psychoceramics Study Group", "affiliation" => [{ "affiliationIdentifier" => "https://ror.org/05gq02987", "name" => "Brown University", "affiliationIdentifierScheme" => "ROR" }], "nameIdentifiers" => [])

        xml = Maremma.from_xml(Base64.decode64(json.dig("data", "attributes", "xml"))).fetch("resource", {})
        expect(xml.dig("creators", "creator")[0]).to eq("affiliation" => { "__content__" => "DataCite", "affiliationIdentifier" => "https://ror.org/04wxnsj81", "affiliationIdentifierScheme" => "ROR" },
                                                        "creatorName" => { "__content__" => "Miller, Elizabeth", "nameType" => "Personal" },
                                                        "familyName" => "Miller",
                                                        "givenName" => "Elizabeth",
                                                        "nameIdentifier" => { "__content__" => "0000-0001-5000-0007", "nameIdentifierScheme" => "ORCID", "schemeURI" => "http://orcid.org/" })
      end
    end

    context "with related_items" do
      let(:xml) { ::Base64.strict_encode64(File.read(file_fixture("datacite-example-relateditems.xml"))) }
      let(:params) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "doi" => "10.14454/10703",
              "xml" => xml,
            },
          },
        }
      end

      it "validates a Doi" do
        post "/dois", params, headers

        expect(last_response.status).to eq(201)

        expect(json.dig("data", "attributes", "relatedItems")).to eq([{ "relationType" => "IsPublishedIn",
                                                                        "relatedItemType" => "Journal",
                                                                        "relatedItemIdentifier" => { "relatedItemIdentifier" => "10.5072/john-smiths-1234",
                                                                                                    "relatedItemIdentifierType" => "DOI",
                                                                                                    "relatedMetadataScheme" => "citeproc+json",
                                                                                                    "schemeURI" => "https://github.com/citation-style-language/schema/raw/master/csl-data.json",
                                                                                                    "schemeType" => "URL" },
                                                                        "creators" => [
                                                                          {
                                                                            "nameType" => "Personal",
                                                                            "name" => "Smith, John",
                                                                            "givenName" => "John",
                                                                            "familyName" => "Smith"
                                                                          }
                                                                        ],
                                                                        "titles" => [
                                                                            { "title" => "Understanding the fictional John Smith" },
                                                                            { "titleType" => "Subtitle", "title" => "A detailed look" }
                                                                        ],
                                                                        "publicationYear" => "1776",
                                                                        "volume" => "776",
                                                                        "issue" => "1",
                                                                        "number" => "1",
                                                                        "numberType" => "Chapter",
                                                                        "firstPage" => "50",
                                                                        "lastPage" => "60",
                                                                        "publisher" => "Example Inc",
                                                                        "edition" => "1",
                                                                        "contributors" => [
                                                                            "contributorType" => "ProjectLeader",
                                                                            "name" => "Hallett, Richard",
                                                                            "givenName" => "Richard",
                                                                            "familyName" => "Hallett",
                                                                            "nameType" => "Personal"
                                                                        ]
                                                                      },
                                                                      {
                                                                        "contributors" => [],
                                                                        "creators" => [],
                                                                        "firstPage" => "249",
                                                                        "lastPage" => "264",
                                                                        "publicationYear" => "2018",
                                                                        "relatedItemIdentifier" => { "relatedItemIdentifier" => "10.1016/j.physletb.2017.11.044",
                                                                                                     "relatedItemIdentifierType" => "DOI" },
                                                                        "relatedItemType" => "Journal",
                                                                        "relationType" => "IsPublishedIn",
                                                                        "titles" => [{ "title" => "Physics letters / B" } ],
                                                                        "volume" => "776"
                                                                      }
                                                                      ])
        expect(json.dig("data", "attributes", "container")).to eq({
          "type" => "Series",
          "title" => "Understanding the fictional John Smith",
          "identifier" => "10.5072/john-smiths-1234",
          "identifierType" => "DOI",
          "issue" => "1",
          "firstPage" => "50",
          "lastPage" => "60",
          "volume" => "776",
          "edition" => "1",
          "number" => "1",
          "chapterNumber" => "1"
        })
        xml = Maremma.from_xml(Base64.decode64(json.dig("data", "attributes", "xml"))).fetch("resource", {})

        expect(xml.dig("relatedItems", "relatedItem")).to eq(
          [{
            "relationType" => "IsPublishedIn",
            "relatedItemType" => "Journal",
            "relatedItemIdentifier" => {
              "relatedItemIdentifierType" => "DOI",
              "relatedMetadataScheme" => "citeproc+json",
              "schemeURI" => "https://github.com/citation-style-language/schema/raw/master/csl-data.json",
              "schemeType" => "URL",
              "__content__" => "10.5072/john-smiths-1234"
              },
            "creators" => {
              "creator" => {
                "creatorName" => { "nameType" => "Personal", "__content__" => "Smith, John" },
                "givenName" => "John",
                "familyName" => "Smith"
              }
            },
            "titles" => {
              "title" => [
                "Understanding the fictional John Smith",
                { "titleType" => "Subtitle", "__content__" => "A detailed look" }
              ]
            },
            "publicationYear" => "1776",
            "volume" => "776",
            "issue" => "1",
            "number" => { "numberType" => "Chapter", "__content__" => "1" },
            "firstPage" => "50",
            "lastPage" => "60",
            "publisher" => "Example Inc",
            "edition" => "1",
            "contributors" => {
              "contributor" => {
                "contributorType" => "ProjectLeader",
                "contributorName" => { "nameType" => "Personal", "__content__" => "Richard, Hallett" },
                "givenName" => "Richard",
                "familyName" => "Hallett"
              }
            }
          },
          {
            "firstPage" => "249",
            "lastPage" => "264",
            "publicationYear" => "2018",
            "relatedItemIdentifier" =>
              { "__content__" => "10.1016/j.physletb.2017.11.044",
              "relatedItemIdentifierType" => "DOI" },
            "relatedItemType" => "Journal",
            "relationType" => "IsPublishedIn",
            "titles" => { "title" => "Physics letters / B" },
            "volume" => "776"
          }
          ]
        )
      end

      it "does not require optional properties" do
        valid_attributes = {
            "data" => {
              "type" => "dois",
              "attributes" => {
                "doi" => "10.14454/relateditems-optional",
                "url" => "http://www.bl.uk/pdf/patspec.pdf",
                "types" => { "bibtex" => "article", "citeproc" => "article-journal", "resourceType" => "BlogPosting", "resourceTypeGeneral" => "Text", "ris" => "RPRT", "schemaOrg" => "ScholarlyArticle" },
                "titles" => [{ "title" => "Eating your own Dog Food" }],
                "publisher" => "DataCite",
                "publicationYear" => 2016,
                "creators" => [{ "familyName" => "Fenner", "givenName" => "Martin", "nameIdentifiers" => [{ "nameIdentifier" => "https://orcid.org/0000-0003-1419-2405", "nameIdentifierScheme" => "ORCID", "schemeUri" => "https://orcid.org" }], "name" => "Fenner, Martin", "nameType" => "Personal" }],
                "source" => "test",
                "event" => "publish",
                "relatedItems" => [{
                  "relatedItemType" => "Journal",
                  "relationType" => "IsPublishedIn",
                  "titles" => [{ "title" => "Physics letters / B" }]
                }],
              },
            },
          }

        post "/dois", valid_attributes, headers

        expect(last_response.status).to eq(201)
        expect(json.dig("data", "attributes", "relatedItems")).to eq([{
          "relatedItemType" => "Journal",
          "relationType" => "IsPublishedIn",
          "titles" => [{ "title" => "Physics letters / B" }]
        }])
      end
    end

    context "with subject classificationcode" do
      let(:xml) { ::Base64.strict_encode64(File.read(file_fixture("datacite.xml"))) }
      let(:params) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "doi" => "10.14454/10703",
              "xml" => xml,
            },
          },
        }
      end

      it "validates a Doi" do
        post "/dois", params, headers

        expect(last_response.status).to eq(201)
        expect(json.dig("data", "attributes", "subjects")[2]).to eq("subject" => "metadata",
                                                                   "classificationCode" => "000")

        xml = Maremma.from_xml(Base64.decode64(json.dig("data", "attributes", "xml"))).fetch("resource", {})

        expect(xml.dig("subjects", "subject")).to eq(
          [
            "datacite",
            "doi",
            {
              "__content__" => "metadata",
              "classificationCode" => "000"
            },
          ]
        )
      end
    end

    context "when the resource_type_general is preprint" do
      let(:xml) { Base64.strict_encode64(file_fixture("datacite.xml").read) }
      let(:types) { { "resourceTypeGeneral" => "Preprint", "resourceType" => "BlogPosting" } }
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
        expect(json.dig("data", "attributes", "types")).to eq("bibtex" => "misc", "citeproc" => "article", "resourceType" => "BlogPosting", "resourceTypeGeneral" => "Preprint", "ris" => "GEN", "schemaOrg" => "CreativeWork")
        expect(json.dig("data", "attributes", "state")).to eq("findable")
      end
    end

    context "schema_org" do
      let(:xml) { Base64.strict_encode64(file_fixture("schema_org_topmed.json").read) }
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "url" => "https://ors.datacite.org/doi:/10.14454/8na3-9s47",
              "xml" => xml,
              "source" => "test",
              "event" => "publish",
            },
          },
        }
      end

      it "updates the record" do
        patch "/dois/10.14454/8na3-9s47", valid_attributes, headers

        expect(last_response.status).to eq(201)
        expect(json.dig("data", "attributes", "url")).to eq("https://ors.datacite.org/doi:/10.14454/8na3-9s47")
        expect(json.dig("data", "attributes", "doi")).to eq("10.14454/8na3-9s47")
        expect(json.dig("data", "attributes", "contentUrl")).to eq(["s3://cgp-commons-public/topmed_open_access/197bc047-e917-55ed-852d-d563cdbc50e4/NWD165827.recab.cram", "gs://topmed-irc-share/public/NWD165827.recab.cram"])
        expect(json.dig("data", "attributes", "titles")).to eq([{ "title" => "NWD165827.recab.cram" }])
        expect(json.dig("data", "attributes", "state")).to eq("findable")

        xml = Maremma.from_xml(Base64.decode64(json.dig("data", "attributes", "xml"))).fetch("resource", {})
        expect(xml.dig("titles", "title")).to eq("NWD165827.recab.cram")
      end
    end

    context "json" do
      let(:attributes) do
        JSON.parse(<<~HEREDOC,
          {
            "doi": "10.14454/9zwb-rb91",
            "event": "publish",
            "types": {
              "resourceType": "Dissertation",
              "resourceTypeGeneral": "Text"
            },
            "creators": [
              {
                "nameType": "Personal",
                "givenName": "Julia M.",
                "familyName": "Rovera",
                "name": "Rovera, Julia M.",
                "affiliation": [{
                  "name": "Drexel University"
                }],
                "nameIdentifiers": [
                  {
                    "schemeUri": "https://orcid.org",
                    "nameIdentifier": "https://orcid.org/0000-0001-7673-8253",
                    "nameIdentifierScheme": "ORCID"
                  }
                ]
              }
            ],
            "titles": [
              {
                "lang": "en",
                "title": "The Relationship Among Sport Type, Micronutrient Intake and Bone Mineral Density in an Athlete Population",
                "titleType": null
              },
              {
                "lang": "en",
                "title": "Subtitle",
                "titleType": "Subtitle"
              }
            ],
            "publisher": "Drexel University",
            "publicationYear": 2019,
            "descriptions": [
              {
                "lang": "en",
                "description": "Diet and physical activity are two modifiable factors that can curtail the development of osteoporosis in the aging population. One purpose of this study was to assess the differences in dietary intake and bone mineral density (BMD) in a Masters athlete population (n=87, n=49 female; 41.06 ± 5.00 years of age) and examine sex- and sport-related differences in dietary and total calcium and vitamin K intake and BMD of the total body, lumbar spine, and dual femoral neck (TBBMD, LSBMD and DFBMD, respectively). Total calcium is defined as calcium intake from diet and supplements. Athletes were categorized as participating in an endurance or interval sport. BMD was measured using dual-energy X-ray absorptiometry (DXA). Data on dietary intake was collected from Block 2005 Food Frequency Questionnaires (FFQs). Dietary calcium, total calcium, or vitamin K intake did not differ between the female endurance and interval athletes. All three BMD sites were significantly different among the female endurance and interval athletes, with female interval athletes having higher BMD at each site (TBBMD: 1.26 ± 0.10 g/cm2, p<0.05; LSBMD: 1.37 ± 0.14 g/cm2, p<0.01; DFBMD: 1.11 ± 0.12 g/cm2, p<0.05, for female interval athletes; TBBMD: 1.19 ± 0.09 g/cm2; LSBMD: 1.23 ± 0.16 g/cm2; DFBMD: 1.04 ± 0.10 g/cm2, for female endurance athletes). Male interval athletes had higher BMD at all three sites (TBBMD 1.44 ± 0.11 g/cm2, p<0.05; LSBMD 1.42 ± 0.15 g/cm2, p=0.179; DFBMD 1.26 ± 0.14 g/cm2, p<0.01, for male interval athletes; TBBMD 1.33 ± 0.11 g/cm2; LSBMD 1.33 ± 0.17 g/cm2; DFBMD 1.10 ± 0.12 g/cm2 for male endurance athletes). Dietary calcium, total daily calcium and vitamin K intake did not differ between the male endurance and interval athletes. This study evaluated the relationship between calcium intake and BMD. No relationship between dietary or total calcium intake and BMD was evident in all female athletes, female endurance athletes or female interval athletes. In all male athletes, there was no significant correlation between dietary or total calcium intake and BMD at any of the measured sites. However, the male interval athlete group had a negative relationship between dietary calcium intake and TBBMD (r=-0.738, p<0.05) and LSBMD (r=-0.738, p<0.05). The negative relationship persisted between total calcium intake and LSBMD (r=-0.714, p<0.05), but not TBBMD, when calcium from supplements was included. The third purpose of this study was to evaluate the relationship between vitamin K intake (as phylloquinone) and BMD. In all female athletes, there was no significant correlation between vitamin K intake and BMD at any of the measured sites. No relationship between vitamin K and BMD was evident in female interval or female endurance athletes. Similarly, there was no relationship between vitamin K intake and BMD in the male endurance and interval groups. The final purpose of this study was to assess the relationship between the Calcium-to-Vitamin K (Ca:K) ratio and BMD. A linear regression model established that the ratio predicted TBBMD in female athletes, F(1,47) = 4.652, p <0.05, and the ratio accounted for 9% of the variability in TBBMD. The regression equation was: predicted TBBMD in a female athlete = 1.250 - 0.008 x (Ca:K). In conclusion, Masters interval athletes have higher BMD than Masters endurance athletes; however, neither dietary or supplemental calcium nor vitamin K were related to BMD in skeletal sites prone to fracture in older adulthood. We found that a Ca:K ratio could predict TBBMD in female athletes. Further research should consider the calcium-to-vitamin K relationship in conjunction with other modifiable, lifestyle factors associated with bone health in the investigation of methods to minimize the development and effect of osteoporosis in the older athlete population.",
                "descriptionType": "Abstract"
              }
            ],
            "url": "https://idea.library.drexel.edu/islandora/object/idea:9531"
          }
        HEREDOC
                  )
      end

      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => attributes,
            "relationships" => {
              "client" => {
                "data" => {
                  "type" => "clients",
                  "id" => client.symbol.downcase,
                },
              },
            },
          },
        }
      end

      it "created the record" do
        post "/dois", valid_attributes, headers

        expect(last_response.status).to eq(201)
        expect(json.dig("data", "attributes", "url")).to eq("https://idea.library.drexel.edu/islandora/object/idea:9531")
        expect(json.dig("data", "attributes", "doi")).to eq("10.14454/9zwb-rb91")
        expect(json.dig("data", "attributes", "types")).to eq("bibtex" => "phdthesis", "citeproc" => "thesis", "resourceType" => "Dissertation", "resourceTypeGeneral" => "Text", "ris" => "THES", "schemaOrg" => "Thesis")
        expect(json.dig("data", "attributes", "descriptions", 0, "description")).to start_with("Diet and physical activity")
        expect(json.dig("data", "attributes", "titles")).to eq([{ "lang" => "en", "title" => "The Relationship Among Sport Type, Micronutrient Intake and Bone Mineral Density in an Athlete Population", "titleType" => nil }, { "lang" => "en", "title" => "Subtitle", "titleType" => "Subtitle" }])
        expect(json.dig("data", "attributes", "state")).to eq("findable")

        xml = Maremma.from_xml(Base64.decode64(json.dig("data", "attributes", "xml"))).fetch("resource", {})
        expect(xml.dig("titles", "title")).to eq([{ "__content__" =>
          "The Relationship Among Sport Type, Micronutrient Intake and Bone Mineral Density in an Athlete Population",
                                                    "xml:lang" => "en" },
                                                  { "__content__" => "Subtitle", "titleType" => "Subtitle", "xml:lang" => "en" }])
      end
    end

    context "when the request has wrong object in nameIdentifiers" do
      let(:valid_attributes) { JSON.parse(file_fixture("datacite_wrong_nameIdentifiers.json").read) }

      it "fails to create a Doi" do
        post "/dois", valid_attributes, headers
        expect(last_response.status).to eq(422)
      end
    end

    # There were no nameIdentifiers in contributors/creators.  Added them so that would be tested.
    context "when the request has wrong object in nameIdentifiers nasa" do
      let(:valid_attributes) { JSON.parse(file_fixture("nasa_error.json").read) }

      it "fails to create a Doi" do
        post "/dois", valid_attributes, headers
        expect(last_response.status).to eq(201)
      end
    end

    # context 'when the request is a large xml file' do
    #   let(:xml) { Base64.strict_encode64(file_fixture('large_file.xml').read) }
    #   let(:valid_attributes) do
    #     {
    #       "data" => {
    #         "type" => "dois",
    #         "attributes" => {
    #           "doi" => "10.14454/10703",
    #           "url" => "http://www.bl.uk/pdf/patspec.pdf",
    #           "xml" => xml,
    #           "event" => "publish"
    #         }
    #       }
    #     }
    #   end

    #   before { post '/dois', valid_attributes.to_json, headers: headers }

    #   it 'creates a Doi' do
    #     expect(json.dig('data', 'attributes', 'url')).to eq("http://www.bl.uk/pdf/patspec.pdf")
    #     expect(json.dig('data', 'attributes', 'doi')).to eq("10.14454/10703")

    #     expect(json.dig('data', 'attributes', 'titles')).to eq([{"title"=>"A dataset with a large file for testing purpose. Will be a but over 2.5 MB"}])
    #     expect(json.dig('data', 'attributes', 'creators')).to eq([{"familyName"=>"Testing", "givenName"=>"Chris Baars At DANS For", "name"=>"Chris Baars At DANS For Testing", "type"=>"Person"}])
    #     expect(json.dig('data', 'attributes', 'publisher')).to eq("DANS/KNAW")
    #     expect(json.dig('data', 'attributes', 'publicationYear')).to eq(2018)
    #     expect(json.dig('data', 'attributes', 'schemaVersion')).to eq("http://datacite.org/schema/kernel-4")
    #     expect(json.dig('data', 'attributes', 'types')).to eq("bibtex"=>"misc", "citeproc"=>"dataset", "resourceType"=>"Dataset", "resourceTypeGeneral"=>"Dataset", "ris"=>"DATA", "schemaOrg"=>"Dataset")

    #     doc = Nokogiri::XML(Base64.decode64(json.dig('data', 'attributes', 'xml')), nil, 'UTF-8', &:noblanks)
    #     expect(doc.at_css("identifier").content).to eq("10.14454/10703")
    #   end

    #   it 'returns status code 201' do
    #     expect(response).to have_http_status(201)
    #   end
    # end

    context "when the request uses namespaced xml" do
      let(:xml) { Base64.strict_encode64(file_fixture("ns0.xml").read) }
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "doi" => "10.14454/10703",
              "url" => "http://www.bl.uk/pdf/patspec.pdf",
              "xml" => xml,
              "event" => "publish",
            },
          },
        }
      end

      it "returns an error that schema is no longer supported" do
        post "/dois", valid_attributes, headers

        expect(last_response.status).to eq(422)
        expect(json.fetch("errors", nil)).to eq([{ "source" => "xml", "title" => "DOI 10.14454/10703: Schema http://datacite.org/schema/kernel-2.2 is no longer supported", "uid" => "10.14454/10703" }])
      end
    end

    context "when the xml request uses unsupported metadata version - kernel-3" do
      let(:xml) { Base64.strict_encode64(file_fixture("ns3.xml").read) }
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "doi" => "10.14454/10703",
              "url" => "http://www.bl.uk/pdf/patspec.pdf",
              "xml" => xml,
              "event" => "publish",
            },
          },
        }
      end

      it "returns an error that schema is no longer supported" do
        post "/dois", valid_attributes, headers

        expect(last_response.status).to eq(422)
        expect(json.fetch("errors", nil)).to eq([{ "source" => "xml", "title" => "DOI 10.14454/10703: Schema http://datacite.org/schema/kernel-3 is no longer supported", "uid" => "10.14454/10703" }])
      end
    end

    context "when the xml request uses unsupported metadata version - kernel-3.0" do
      let(:xml) { Base64.strict_encode64(file_fixture("ns30.xml").read) }
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "doi" => "10.14454/10703",
              "url" => "http://www.bl.uk/pdf/patspec.pdf",
              "xml" => xml,
              "event" => "publish",
            },
          },
        }
      end

      it "returns an error that schema is no longer supported" do
        post "/dois", valid_attributes, headers

        expect(last_response.status).to eq(422)
        expect(json.fetch("errors", nil)).to eq([{ "source" => "xml", "title" => "DOI 10.14454/10703: Schema http://datacite.org/schema/kernel-3.0 is no longer supported", "uid" => "10.14454/10703" }])
      end
    end

    context "when the xml request uses unsupported metadata version - kernel-3.1" do
      let(:xml) { Base64.strict_encode64(file_fixture("ns31.xml").read) }
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "doi" => "10.14454/10703",
              "url" => "http://www.bl.uk/pdf/patspec.pdf",
              "xml" => xml,
              "event" => "publish",
            },
          },
        }
      end

      it "returns an error that schema is no longer supported" do
        post "/dois", valid_attributes, headers

        expect(last_response.status).to eq(422)
        expect(json.fetch("errors", nil)).to eq([{ "source" => "xml", "title" => "DOI 10.14454/10703: Schema http://datacite.org/schema/kernel-3.1 is no longer supported", "uid" => "10.14454/10703" }])
      end
    end

    context "when the request uses schema 4.0" do
      let(:xml) { Base64.strict_encode64(file_fixture("schema_4.0.xml").read) }
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "doi" => "10.14454/10703",
              "url" => "http://www.bl.uk/pdf/patspec.pdf",
              "xml" => xml,
              "event" => "publish",
            },
          },
        }
      end

      it "creates a Doi" do
        post "/dois", valid_attributes, headers

        expect(last_response.status).to eq(201)
        expect(json.dig("data", "attributes", "doi")).to eq("10.14454/10703")
        expect(json.dig("data", "attributes", "titles")).to eq([{ "title" => "Southern Sierra Critical Zone Observatory (SSCZO), Providence Creek meteorological data, soil moisture and temperature, snow depth and air temperature" }])
        expect(json.dig("data", "attributes", "schemaVersion")).to eq("http://datacite.org/schema/kernel-4")
        expect(json.dig("data", "attributes", "state")).to eq("findable")
      end
    end

    context "when the request uses schema 4.2" do
      let(:xml) { Base64.strict_encode64(file_fixture("schema_4.2.xml").read) }
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "doi" => "10.14454/10703",
              "url" => "http://www.bl.uk/pdf/patspec.pdf",
              "xml" => xml,
              "event" => "publish",
            },
          },
        }
      end

      it "creates a Doi" do
        post "/dois", valid_attributes, headers

        expect(last_response.status).to eq(201)
        expect(json.dig("data", "attributes", "doi")).to eq("10.14454/10703")
        expect(json.dig("data", "attributes", "titles")).to eq([{ "title" => "Southern Sierra Critical Zone Observatory (SSCZO), Providence Creek meteorological data, soil moisture and temperature, snow depth and air temperature" }])
        expect(json.dig("data", "attributes", "schemaVersion")).to eq("http://datacite.org/schema/kernel-4")
        expect(json.dig("data", "attributes", "state")).to eq("findable")
      end
    end

    context "when the request uses schema 4.5" do
      let(:xml) { Base64.strict_encode64(file_fixture("datacite-example-full-v4.5.xml").read) }
      let(:doi) { "10.14454/10703" }
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "doi" => doi,
              "url" => "http://www.bl.uk/pdf/patspec.pdf",
              "xml" => xml,
              "event" => "publish",
            },
          },
        }
      end

      it "creates a Doi" do
        post "/dois", valid_attributes, headers

        expect(last_response.status).to eq(201)
        expect(json.dig("data", "attributes", "doi")).to eq(doi)
        expect(json.dig("data", "attributes", "schemaVersion")).to eq("http://datacite.org/schema/kernel-4")
        expect(json.dig("data", "attributes", "state")).to eq("findable")
        expect(json.dig("data", "attributes", "publisher")).to eq("Example Publisher")

        expect(json.dig("data", "attributes", "relatedIdentifiers", 34)).to eq(
          {
            "relatedIdentifier" => "10.1016/j.epsl.2011.11.037",
            "relatedIdentifierType" => "DOI",
            "relationType" => "Collects",
            "resourceTypeGeneral" => "Other",
          }
        )
        expect(json.dig("data", "attributes", "relatedIdentifiers", 35)).to eq(
          {
            "relatedIdentifier" => "10.1016/j.epsl.2011.11.037",
            "relatedIdentifierType" => "DOI",
            "relationType" => "IsCollectedBy",
            "resourceTypeGeneral" => "Other"
          }
        )

        expect(json.dig("data", "attributes", "relatedItems", 1, "relationType")).to eq("Collects")
        expect(json.dig("data", "attributes", "relatedItems", 1, "titles", 0, "title")).to eq("Journal of Metadata Examples - Collects")
        expect(json.dig("data", "attributes", "relatedItems", 2, "relationType")).to eq("IsCollectedBy")
        expect(json.dig("data", "attributes", "relatedItems", 2, "titles", 0, "title")).to eq("Journal of Metadata Examples - IsCollectedBy")

        doc = Nokogiri::XML(Base64.decode64(json.dig("data", "attributes", "xml")), nil, "UTF-8", &:noblanks)
        expect(doc.at_css("publisher").content).to eq("Example Publisher")
        expect(doc.at_css("publisher")["publisherIdentifier"]).to eq("https://ror.org/04z8jg394")
        expect(doc.at_css("publisher")["publisherIdentifierScheme"]).to eq("ROR")
        expect(doc.at_css("publisher")["schemeURI"]).to eq("https://ror.org/")
        expect(doc.at_css("publisher")["xml:lang"]).to eq("en")

        expect(Doi.where(doi: "10.14454/10703").first.publisher).to eq(
          {
            "name" => "Example Publisher",
            "publisherIdentifier" => "https://ror.org/04z8jg394",
            "publisherIdentifierScheme" => "ROR",
            "schemeUri" => "https://ror.org/",
            "lang" => "en",
          }
        )
      end

      it "creates a Doi with publisher param set to true" do
        post "/dois?publisher=true", valid_attributes, headers

        expect(last_response.status).to eq(201)
        expect(json.dig("data", "attributes", "doi")).to eq(doi)
        expect(json.dig("data", "attributes", "schemaVersion")).to eq("http://datacite.org/schema/kernel-4")
        expect(json.dig("data", "attributes", "state")).to eq("findable")
        expect(json.dig("data", "attributes", "publisher")).to eq(
          {
            "name" => "Example Publisher",
            "publisherIdentifier" => "https://ror.org/04z8jg394",
            "publisherIdentifierScheme" => "ROR",
            "schemeUri" => "https://ror.org/",
            "lang" => "en",
          }
        )
      end
    end

    context "when the request is valid with publisher as a hash" do
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "doi" => "10.14454/10703",
              "url" => "http://www.bl.uk/pdf/patspec.pdf",
              "types" => { "resourceTypeGeneral" => "Text" },
              "titles" => [{ "title" => "Eating your own Dog Food" }],
              "publisher" => {
                "name" => "DataCite",
                "publisherIdentifier" => "https://ror.org/04wxnsj81",
                "publisherIdentifierScheme" => "ROR",
                "schemeUri" => "https://ror.org/",
                "lang" => "en",
              },
              "publicationYear" => 2016,
              "creators" => [{ "familyName" => "Fenner", "givenName" => "Martin", "nameIdentifiers" => [{ "nameIdentifier" => "https://orcid.org/0000-0003-1419-2405", "nameIdentifierScheme" => "ORCID", "schemeUri" => "https://orcid.org" }], "name" => "Fenner, Martin", "nameType" => "Personal" }],
              "event" => "publish",
            },
          },
        }
      end

      it "creates a Doi with publisher param not set" do
        post "/dois", valid_attributes, headers

        expect(last_response.status).to eq(201)
        expect(json.dig("data", "attributes", "url")).to eq("http://www.bl.uk/pdf/patspec.pdf")
        expect(json.dig("data", "attributes", "doi")).to eq("10.14454/10703")
        expect(json.dig("data", "attributes", "titles")).to eq([{ "title" => "Eating your own Dog Food" }])
        expect(json.dig("data", "attributes", "creators")).to eq([{ "affiliation" => [], "familyName" => "Fenner", "givenName" => "Martin", "nameIdentifiers" => [{ "nameIdentifier" => "https://orcid.org/0000-0003-1419-2405", "nameIdentifierScheme" => "ORCID", "schemeUri" => "https://orcid.org" }], "name" => "Fenner, Martin", "nameType" => "Personal" }])
        expect(json.dig("data", "attributes", "publisher")).to eq("DataCite")
        expect(json.dig("data", "attributes", "publicationYear")).to eq(2016)
        expect(json.dig("data", "attributes", "state")).to eq("findable")

        expect(Doi.where(doi: "10.14454/10703").first.publisher).to eq(
          {
            "name" => "DataCite",
            "publisherIdentifier" => "https://ror.org/04wxnsj81",
            "publisherIdentifierScheme" => "ROR",
            "schemeUri" => "https://ror.org/",
            "lang" => "en",
          }
        )
      end

      it "creates a Doi with publisher param set to true" do
        post "/dois?publisher=true", valid_attributes, headers

        expect(last_response.status).to eq(201)
        expect(json.dig("data", "attributes", "url")).to eq("http://www.bl.uk/pdf/patspec.pdf")
        expect(json.dig("data", "attributes", "doi")).to eq("10.14454/10703")
        expect(json.dig("data", "attributes", "titles")).to eq([{ "title" => "Eating your own Dog Food" }])
        expect(json.dig("data", "attributes", "creators")).to eq([{ "affiliation" => [], "familyName" => "Fenner", "givenName" => "Martin", "nameIdentifiers" => [{ "nameIdentifier" => "https://orcid.org/0000-0003-1419-2405", "nameIdentifierScheme" => "ORCID", "schemeUri" => "https://orcid.org" }], "name" => "Fenner, Martin", "nameType" => "Personal" }])
        expect(json.dig("data", "attributes", "publisher")).to eq(
          {
            "name" => "DataCite",
            "publisherIdentifier" => "https://ror.org/04wxnsj81",
            "publisherIdentifierScheme" => "ROR",
            "schemeUri" => "https://ror.org/",
            "lang" => "en",
          }
        )
        expect(json.dig("data", "attributes", "publicationYear")).to eq(2016)
        expect(json.dig("data", "attributes", "state")).to eq("findable")
      end
    end

    context "when the request uses namespaced xml" do
      let(:xml) { Base64.strict_encode64(file_fixture("ns0.xml").read) }
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "doi" => "10.14454/10703",
              "url" => "http://www.bl.uk/pdf/patspec.pdf",
              "xml" => xml,
              "event" => "publish",
            },
          },
        }
      end

      it "returns an error that schema is no longer supported" do
        post "/dois", valid_attributes, headers

        expect(last_response.status).to eq(422)
        expect(json.fetch("errors", nil)).to eq([{ "source" => "xml", "title" => "DOI 10.14454/10703: Schema http://datacite.org/schema/kernel-2.2 is no longer supported", "uid" => "10.14454/10703" }])
      end
    end

    context "when the title changes" do
      let(:titles) { [ { "title" => "Referee report. For: RESEARCH-3482 [version 5; referees: 1 approved, 1 approved with reservations]" } ] }
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
              "titles" => titles,
              "event" => "publish",
            },
          },
        }
      end

      it "creates a Doi" do
        post "/dois", valid_attributes, headers

        expect(last_response.status).to eq(201)
        expect(json.dig("data", "attributes", "doi")).to eq("10.14454/10703")
        expect(json.dig("data", "attributes", "titles")).to eq([{ "title" => "Referee report. For: RESEARCH-3482 [version 5; referees: 1 approved, 1 approved with reservations]" }])
        expect(json.dig("data", "attributes", "url")).to eq("http://www.bl.uk/pdf/patspec.pdf")
        expect(json.dig("data", "attributes", "source")).to eq("test")
        expect(json.dig("data", "attributes", "state")).to eq("findable")
      end
    end

    context "when the url changes ftp url" do
      let(:url) { "ftp://ftp.library.noaa.gov/noaa_documents.lib/NOS/NGS/TM_NOS_NGS/TM_NOS_NGS_72.pdf" }
      let(:xml) { Base64.strict_encode64(file_fixture("datacite.xml").read) }
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "doi" => "10.14454/10703",
              "url" => url,
              "xml" => xml,
              "event" => "publish",
            },
          },
        }
      end

      it "creates a Doi" do
        post "/dois", valid_attributes, headers

        expect(last_response.status).to eq(201)
        expect(json.dig("data", "attributes", "doi")).to eq("10.14454/10703")
        expect(json.dig("data", "attributes", "url")).to eq(url)
        expect(json.dig("data", "attributes", "state")).to eq("findable")
      end
    end

    context "when the titles changes to nil" do
      let(:xml) { Base64.strict_encode64(file_fixture("datacite.xml").read) }
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "doi" => "10.14454/10703",
              "url" => "http://www.bl.uk/pdf/patspec.pdf",
              "xml" => xml,
              "titles" => nil,
              "event" => "publish",
            },
          },
        }
      end

      it "creates a Doi" do
        post "/dois", valid_attributes, headers

        expect(last_response.status).to eq(201)
        expect(json.dig("data", "attributes", "doi")).to eq("10.14454/10703")
        expect(json.dig("data", "attributes", "titles")).to eq([{ "title" => "Eating your own Dog Food" }])
        expect(json.dig("data", "attributes", "url")).to eq("http://www.bl.uk/pdf/patspec.pdf")
        expect(json.dig("data", "attributes", "state")).to eq("findable")
      end
    end

    context "when the titles changes to blank" do
      let(:xml) { Base64.strict_encode64(file_fixture("datacite.xml").read) }
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "doi" => "10.14454/10703",
              "url" => "http://www.bl.uk/pdf/patspec.pdf",
              "xml" => xml,
              "titles" => nil,
              "event" => "publish",
            },
          },
        }
      end

      it "creates a Doi" do
        post "/dois", valid_attributes, headers

        expect(last_response.status).to eq(201)
        expect(json.dig("data", "attributes", "doi")).to eq("10.14454/10703")
        expect(json.dig("data", "attributes", "titles")).to eq([{ "title" => "Eating your own Dog Food" }])
        expect(json.dig("data", "attributes", "url")).to eq("http://www.bl.uk/pdf/patspec.pdf")
        expect(json.dig("data", "attributes", "state")).to eq("findable")
      end
    end

    context "when the creators change" do
      let(:creators) { [{ "affiliation" => [], "nameIdentifiers" => [], "name" => "Ollomi, Benjamin" }, { "affiliation" => [], "nameIdentifiers" => [], "name" => "Duran, Patrick" }] }
      let(:xml) { Base64.strict_encode64(file_fixture("datacite.xml").read) }
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "doi" => "10.14454/10703",
              "url" => "http://www.bl.uk/pdf/patspec.pdf",
              "xml" => xml,
              "creators" => creators,
              "event" => "publish",
            },
          },
        }
      end

      it "creates a Doi" do
        post "/dois", valid_attributes, headers

        expect(last_response.status).to eq(201)
        expect(json.dig("data", "attributes", "doi")).to eq("10.14454/10703")
        expect(json.dig("data", "attributes", "creators")).to eq(creators)
        expect(json.dig("data", "attributes", "url")).to eq("http://www.bl.uk/pdf/patspec.pdf")
        expect(json.dig("data", "attributes", "state")).to eq("findable")
      end
    end

    context "when doi has unpermitted characters" do
      let(:xml) { Base64.strict_encode64(file_fixture("datacite.xml").read) }
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "doi" => "10.14454/107+03",
              "url" => "http://www.bl.uk/pdf/patspec.pdf",
              "xml" => xml,
              "source" => "test",
              "event" => "publish",
            },
          },
        }
      end

      it "returns validation error" do
        post "/dois", valid_attributes, headers

        expect(last_response.status).to eq(422)
        expect(json.dig("errors")).to eq([{ "source" => "doi", "title" => "Is invalid", "uid" => "10.14454/107+03" }])
      end
    end

    context "creators no xml" do
      let(:creators) { [{ "name" => "Ollomi, Benjamin" }, { "name" => "Duran, Patrick" }] }
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "doi" => "10.14454/10703",
              "url" => "http://www.bl.uk/pdf/patspec.pdf",
              "xml" => nil,
              "creators" => creators,
              "event" => "publish",
            },
          },
        }
      end

      it "returns validation error" do
        post "/dois", valid_attributes, headers

        expect(last_response.status).to eq(422)
        expect(json.dig("errors")).to eq([
          { "source" => "metadata", "title" => "Is invalid", "uid" => "10.14454/10703" }
        ])
      end
    end

    context "draft doi no url" do
      let(:prefix) { create(:prefix, uid: "10.14454") }
      let!(:client_prefix) { create(:client_prefix, client: client, prefix: prefix) }

      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "doi" => "10.14454/10704",
            },
          },
        }
      end

      it "creates a Doi" do
        post "/dois", valid_attributes, headers

        expect(last_response.status).to eq(201)
        expect(json.dig("data", "attributes", "doi")).to eq("10.14454/10704")
        expect(json.dig("data", "attributes", "state")).to eq("draft")
      end
    end

    context "when the request is invalid" do
      let(:not_valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "doi" => "10.aaaa03",
              "url" => "http://www.bl.uk/pdf/patspec.pdf",
            },
          },
        }
      end

      it "returns a validation failure message" do
        post "/dois", not_valid_attributes, headers

        expect(last_response.status).to eq(403)
        expect(json["errors"]).to eq([{ "status" => "403", "title" => "You are not authorized to access this resource." }])
      end
    end

    context "when the xml is invalid draft doi" do
      let(:xml) { Base64.strict_encode64(file_fixture("datacite_missing_creator.xml").read) }
      let(:not_valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "doi" => "10.14454/10703",
              "url" => "http://www.bl.uk/pdf/patspec.pdf",
              "xml" => xml,
            },
          },
        }
      end

      it "creates a Doi" do
        post "/dois", not_valid_attributes, headers

        expect(last_response.status).to eq(201)
        expect(json.dig("data", "attributes", "doi")).to eq("10.14454/10703")
        expect(json.dig("data", "attributes", "titles")).to eq([{ "title" => "Eating your own Dog Food" }])
        expect(json.dig("data", "attributes", "url")).to eq("http://www.bl.uk/pdf/patspec.pdf")
        expect(json.dig("data", "attributes", "creators")).to be_blank
      end
    end

    context "when the xml is invalid" do
      let(:xml) { Base64.strict_encode64(file_fixture("datacite_missing_creator.xml").read) }
      let(:not_valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "doi" => "10.14454/4K3M-NYVG",
              "url" => "http://www.bl.uk/pdf/patspec.pdf",
              "xml" => xml,
              "event" => "publish",
            },
          },
        }
      end

      it "returns a validation failure message" do
        post "/dois", not_valid_attributes, headers

        expect(last_response.status).to eq(422)
        expect(json["errors"]).to eq([{ "source" => "creators", "title" => "DOI 10.14454/4k3m-nyvg: Missing child element(s). Expected is ( {http://datacite.org/schema/kernel-4}creator ). at line 4, column 0", "uid" => "10.14454/4k3m-nyvg" }])
      end
    end

    describe "POST /dois/validate" do
      context "validates" do
        let(:xml) { ::Base64.strict_encode64(File.read(file_fixture("datacite.xml"))) }
        let(:params) do
          {
            "data" => {
              "type" => "dois",
              "attributes" => {
                "doi" => "10.14454/10703",
                "xml" => xml,
              },
            },
          }
        end

        it "validates a Doi" do
          post "/dois/validate", params, headers

          expect(last_response.status).to eq(200)
          expect(json.dig("data", "attributes", "doi")).to eq("10.14454/10703")
          expect(json.dig("data", "attributes", "titles")).to eq([{ "title" => "Eating your own Dog Food" }])
          expect(json.dig("data", "attributes", "dates")).to eq([{ "date" => "2016-12-20", "dateType" => "Created" }, { "date" => "2016-12-20", "dateType" => "Issued" }, { "date" => "2016-12-20", "dateType" => "Updated" }])
        end
      end

      context "validatation fails with unpermitted characters in new DOI" do
        let(:xml) { ::Base64.strict_encode64(File.read(file_fixture("datacite.xml"))) }
        let(:params) do
          {
            "data" => {
              "type" => "dois",
              "attributes" => {
                "doi" => "10.14454/107+03",
                "xml" => xml,
              },
            },
          }
        end

        it "returns validation error" do
          post "/dois/validate", params, headers

          expect(json.dig("errors")).to eq([{ "source" => "doi", "title" => "Is invalid", "uid" => "10.14454/107+03" }])
        end
      end

      context "validates schema 4.5 xml" do
        let(:xml) { ::Base64.strict_encode64(File.read(file_fixture("datacite-example-full-v4.5.xml"))) }
        let(:params) do
          {
            "data" => {
              "type" => "dois",
              "attributes" => {
                "doi" => "10.14454/10703",
                "xml" => xml,
              },
            },
          }
        end

        it "validates a Doi" do
          post "/dois/validate", params, headers

          expect(last_response.status).to eq(200)
          expect(json.dig("data", "attributes", "doi")).to eq("10.14454/10703")
          expect(json.dig("data", "attributes", "titles", 0)).to eq({ "title" => "Example Title", "lang" => "en" })
          expect(json.dig("data", "attributes", "relatedIdentifiers").last).to eq({ "relatedIdentifierType" => "DOI", "relationType" => "IsCollectedBy", "resourceTypeGeneral" => "Other", "relatedIdentifier" => "10.1016/j.epsl.2011.11.037" })
        end
      end

      context "when the creators are missing" do
        let(:xml) { ::Base64.strict_encode64(File.read(file_fixture("datacite_missing_creator.xml"))) }
        let(:params) do
          {
            "data" => {
              "type" => "dois",
              "attributes" => {
                "doi" => "10.14454/10703",
                "xml" => xml,
              },
            },
          }
        end

        it "validates a Doi" do
          post "/dois/validate", params, headers

          expect(last_response.status).to eq(200)
          expect(json["errors"].size).to eq(1)
          expect(json["errors"].first).to eq("source" => "creators", "title" => "DOI 10.14454/10703: Missing child element(s). Expected is ( {http://datacite.org/schema/kernel-4}creator ). at line 4, column 0", "uid" => "10.14454/10703")
        end
      end

      context "when the creators are malformed" do
        let(:xml) { ::Base64.strict_encode64(File.read(file_fixture("datacite_malformed_creator.xml"))) }
        let(:params) do
          {
            "data" => {
              "type" => "dois",
              "attributes" => {
                "doi" => "10.14454/10703",
                "xml" => xml,
              },
            },
          }
        end

        it "validates a Doi" do
          post "/dois/validate", params, headers

          expect(last_response.status).to eq(200)
          expect(json["errors"].size).to eq(1)
          expect(json["errors"].first).to eq("source" => "creatorName", "title" => "DOI 10.14454/10703: This element is not expected. Expected is ( {http://datacite.org/schema/kernel-4}affiliation ). at line 16, column 0", "uid" => "10.14454/10703")
        end
      end

      context "when attribute type names are wrong" do
        let(:xml) { ::Base64.strict_encode64(File.read(file_fixture("datacite_malformed_creator_name_type.xml"))) }
        let(:params) do
          {
            "data" => {
              "type" => "dois",
              "attributes" => {
                "doi" => "10.14454/10703",
                "xml" => xml,
              },
            },
          }
        end

        it "validates types are in right format" do
          post "/dois/validate", params, headers

          expect(last_response.status).to eq(200)
          expect(json["errors"].first).to eq("source" => "creatorName', attribute 'nameType", "title" => "DOI 10.14454/10703: [facet 'enumeration'] The value 'personal' is not an element of the set {'Organizational', 'Personal'}. at line 12, column 0", "uid" => "10.14454/10703")
        end
      end

      context "validates citeproc" do
        let(:xml) { ::Base64.strict_encode64(File.read(file_fixture("citeproc.json"))) }
        let(:params) do
          {
            "data" => {
              "type" => "dois",
              "attributes" => {
                "doi" => "10.14454/10703",
                "xml" => xml,
              },
            },
          }
        end

        it "validates a Doi" do
          post "/dois/validate", params, headers

          expect(last_response.status).to eq(200)
          expect(json.dig("data", "attributes", "doi")).to eq("10.14454/10703")
          expect(json.dig("data", "attributes", "titles")).to eq([{ "title" => "Eating your own Dog Food" }])
          expect(json.dig("data", "attributes", "dates")).to eq([{ "date" => "2016-12-20", "dateType" => "Issued" }])
        end
      end

      context "validates codemeta" do
        let(:xml) { ::Base64.strict_encode64(File.read(file_fixture("codemeta.json"))) }
        let(:params) do
          {
            "data" => {
              "type" => "dois",
              "attributes" => {
                "doi" => "10.14454/10703",
                "xml" => xml,
              },
            },
          }
        end

        it "validates a Doi" do
          post "/dois/validate", params, headers

          expect(last_response.status).to eq(200)
          expect(json.dig("data", "attributes", "doi")).to eq("10.14454/10703")
          expect(json.dig("data", "attributes", "titles")).to eq([{ "title" => "R Interface to the DataONE REST API" }])
          expect(json.dig("data", "attributes", "dates")).to eq([{ "date" => "2016-05-27", "dateType" => "Issued" }, { "date" => "2016-05-27", "dateType" => "Created" }, { "date" => "2016-05-27", "dateType" => "Updated" }])
        end
      end

      context "validates crosscite" do
        let(:xml) { ::Base64.strict_encode64(File.read(file_fixture("crosscite.json"))) }
        let(:params) do
          {
            "data" => {
              "type" => "dois",
              "attributes" => {
                "doi" => "10.14454/10703",
                "xml" => xml,
              },
            },
          }
        end

        it "validates a Doi" do
          post "/dois/validate", params, headers

          expect(last_response.status).to eq(200)
          expect(json.dig("data", "attributes", "doi")).to eq("10.14454/10703")
          expect(json.dig("data", "attributes", "titles")).to eq([{ "title" => "Analysis Tools for Crossover Experiment of UI using Choice Architecture" }])
          expect(json.dig("data", "attributes", "dates")).to eq([{ "date" => "2016-03-27", "dateType" => "Issued" }])
        end
      end

      context "validates bibtex" do
        let(:xml) { ::Base64.strict_encode64(File.read(file_fixture("crossref.bib"))) }
        let(:params) do
          {
            "data" => {
              "type" => "dois",
              "attributes" => {
                "doi" => "10.14454/10703",
                "xml" => xml,
              },
            },
          }
        end

        it "validates a Doi" do
          post "/dois/validate", params, headers

          expect(last_response.status).to eq(200)
          expect(json.dig("data", "attributes", "doi")).to eq("10.14454/10703")
          expect(json.dig("data", "attributes", "titles")).to eq([{ "title" => "Automated quantitative histology reveals vascular morphodynamics during Arabidopsis hypocotyl secondary growth" }])
          expect(json.dig("data", "attributes", "dates")).to eq([{ "date" => "2014", "dateType" => "Issued" }])
        end
      end

      context "validates ris" do
        let(:xml) { ::Base64.strict_encode64(File.read(file_fixture("crossref.ris"))) }
        let(:params) do
          {
            "data" => {
              "type" => "dois",
              "attributes" => {
                "doi" => "10.14454/10703",
                "xml" => xml,
              },
            },
          }
        end

        it "validates a Doi" do
          post "/dois/validate", params, headers

          expect(last_response.status).to eq(200)
          expect(json.dig("data", "attributes", "doi")).to eq("10.14454/10703")
          expect(json.dig("data", "attributes", "titles")).to eq([{ "title" => "Automated quantitative histology reveals vascular morphodynamics during Arabidopsis hypocotyl secondary growth" }])
          expect(json.dig("data", "attributes", "dates")).to eq([{ "date" => "2014", "dateType" => "Issued" }])
        end
      end

      context "validates crossref xml" do
        let(:xml) { ::Base64.strict_encode64(File.read(file_fixture("crossref.xml"))) }
        let(:params) do
          {
            "data" => {
              "type" => "dois",
              "attributes" => {
                "doi" => "10.14454/10703",
                "xml" => xml,
              },
            },
          }
        end

        it "validates a Doi" do
          post "/dois/validate", params, headers

          expect(last_response.status).to eq(200)
          expect(json.dig("data", "attributes", "doi")).to eq("10.14454/10703")
          expect(json.dig("data", "attributes", "titles")).to eq([{ "title" => "Automated quantitative histology reveals vascular morphodynamics during Arabidopsis hypocotyl secondary growth" }])
          expect(json.dig("data", "attributes", "dates")).to eq([{ "date" => "2014-02-11", "dateType" => "Issued" }, { "date" => "2018-08-23T13:41:49Z", "dateType" => "Updated" }])
        end
      end

      context "validates schema.org" do
        let(:xml) { ::Base64.strict_encode64(File.read(file_fixture("schema_org.json"))) }
        let(:params) do
          {
            "data" => {
              "type" => "dois",
              "attributes" => {
                "doi" => "10.14454/10703",
                "xml" => xml,
              },
            },
          }
        end

        it "validates a Doi" do
          post "/dois/validate", params, headers

          expect(last_response.status).to eq(200)
          expect(json.dig("data", "attributes", "doi")).to eq("10.14454/10703")
          expect(json.dig("data", "attributes", "titles")).to eq([{ "title" => "Eating your own Dog Food" }])
          expect(json.dig("data", "attributes", "dates")).to eq([{ "date" => "2016-12-20", "dateType" => "Issued" }, { "date" => "2016-12-20", "dateType" => "Created" }, { "date" => "2016-12-20", "dateType" => "Updated" }])
        end
      end
    end

    # Invalid contributor type in schema 4.0
    context "update contributor type with funder", elasticsearch: true do
      let(:update_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "contributors" => [{ "contributorType" => "Funder", "name" => "Wellcome Trust", "nameType" => "Organizational" }],
            },
          },
        }
      end

      it "does not update the Doi" do
        patch "/dois/#{doi.doi}", update_attributes, headers

        expect(last_response.status).to eq(422)
        expect(json["errors"][0]["title"]).to match(/Contributor '{.*}' has a contributor type that is not supported in schema 4: '*'./)
      end
    end

    # Missing contributor type.
    context "update contributor type with funder", elasticsearch: true do
      let(:update_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "contributors" => [{ "contributorType" => "", "name" => "Wellcome Trust", "nameType" => "Organizational" }],
            },
          },
        }
      end

      it "does not update the Doi" do
        patch "/dois/#{doi.doi}", update_attributes, headers

        expect(last_response.status).to eq(422)
        expect(json["errors"][0]["title"]).to match(/Contributor '{.*}' is missing a required element: contributor type./)
      end
    end

    # Missing contributor type.
    context "update contributor type with funder", elasticsearch: true do
      let(:update_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "contributors" => [{ "contributorType" => nil, "name" => "Wellcome Trust", "nameType" => "Organizational" }],
            },
          },
        }
      end

      it "does not update the Doi" do
        patch "/dois/#{doi.doi}", update_attributes, headers

        expect(last_response.status).to eq(422)
        expect(json["errors"][0]["title"]).to match(/Contributor '{.*}' is missing a required element: contributor type./)
      end
    end

    # Missing contributor type.
    context "update contributor type with funder", elasticsearch: true do
      let(:update_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "contributors" => [{ "name" => "Wellcome Trust", "nameType" => "Organizational" }],
            },
          },
        }
      end

      it "does not update the Doi" do
        patch "/dois/#{doi.doi}", update_attributes, headers

        expect(last_response.status).to eq(422)
        expect(json["errors"][0]["title"]).to match(/Contributor '{.*}' is missing a required element: contributor type./)
      end
    end

    context "update rightsList", elasticsearch: true do
      let(:rights_list) { [{ "rightsIdentifier" => "CC0-1.0" }] }
      let(:update_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "rightsList" => rights_list,
            },
          },
        }
      end

      it "updates the Doi" do
        patch "/dois/#{doi.doi}", update_attributes, headers

        DataciteDoi.import
        sleep 2

        get "/dois", nil, headers

        expect(last_response.status).to eq(200)
        expect(json["data"].size).to eq(1)
        expect(json.dig("data", 0, "attributes", "rightsList")).to eq([{ "rights" => "Creative Commons Zero v1.0 Universal",
                                                                         "rightsIdentifier" => "cc0-1.0",
                                                                         "rightsIdentifierScheme" => "SPDX",
                                                                         "rightsUri" => "https://creativecommons.org/publicdomain/zero/1.0/legalcode",
                                                                         "schemeUri" => "https://spdx.org/licenses/" }])
        expect(json.dig("meta", "total")).to eq(1)
        expect(json.dig("meta", "affiliations")).to eq([{ "count" => 1, "id" => "ror.org/04wxnsj81", "title" => "DataCite" }])
        expect(json.dig("meta", "licenses")).to eq([{ "count" => 1, "id" => "cc0-1.0", "title" => "CC0-1.0" }])
      end
    end

    context "update rightsList with rightsUri", elasticsearch: true do
      let(:rights_list) do
        [{
          "rightsUri" => "https://creativecommons.org/publicdomain/zero/1.0/",
        }]
      end
      let(:update_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "rightsList" => rights_list,
            },
          },
        }
      end

      it "updates the Doi" do
        patch "/dois/#{doi.doi}", update_attributes, headers

        DataciteDoi.import
        sleep 2

        get "/dois", nil, headers

        expect(last_response.status).to eq(200)
        expect(json["data"].size).to eq(1)
        expect(json.dig("data", 0, "attributes", "rightsList")).to eq(rights_list)
        expect(json.dig("meta", "total")).to eq(1)
        expect(json.dig("meta", "affiliations")).to eq([{ "count" => 1, "id" => "ror.org/04wxnsj81", "title" => "DataCite" }])
        # expect(json.dig('meta', 'licenses')).to eq([{"count"=>1, "id"=>"CC0-1.0", "title"=>"CC0-1.0"}])
      end
    end

    context "update subjects" do
      let(:subjects) do
        [{ "subject" => "80505 Web Technologies (excl. Web Search)",
           "schemeUri" => "http://www.abs.gov.au/ausstats/abs@.nsf/0/6BB427AB9696C225CA2574180004463E",
           "subjectScheme" => "FOR",
           "lang" => "en",
           "classificationCode" => "001" }]
      end
      let(:update_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "subjects" => subjects,
            },
          },
        }
      end

      it "updates the Doi" do
        patch "/dois/#{doi.doi}", update_attributes, headers

        expect(json.dig("data", "attributes", "subjects")).to eq([{ "lang" => "en",
                                                                    "schemeUri" => "http://www.abs.gov.au/ausstats/abs@.nsf/0/6BB427AB9696C225CA2574180004463E",
                                                                    "subject" => "80505 Web Technologies (excl. Web Search)",
                                                                    "subjectScheme" => "FOR",
                                                                    "classificationCode" => "001"
                                                                  },
                                                                  { "schemeUri" => "http://www.oecd.org/science/inno/38235147.pdf",
                                                                    "subject" => "FOS: Computer and information sciences",
                                                                    "subjectScheme" => "Fields of Science and Technology (FOS)" }])
      end
    end

    context "update contentUrl" do
      let(:content_url) { ["s3://cgp-commons-public/topmed_open_access/197bc047-e917-55ed-852d-d563cdbc50e4/NWD165827.recab.cram", "gs://topmed-irc-share/public/NWD165827.recab.cram"] }
      let(:update_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "contentUrl" => content_url,
            },
          },
        }
      end

      it "updates the Doi" do
        patch "/dois/#{doi.doi}", update_attributes, headers

        expect(last_response.status).to eq(200)
        expect(json.dig("data", "attributes", "contentUrl")).to eq(content_url)
      end
    end

    context "update multiple affiliations" do
      let(:creators) { [{ "name" => "Ollomi, Benjamin", "affiliation" => [{ "name" => "Cambridge University" }, { "name" => "EMBL-EBI" }], "nameIdentifiers" => [] }] }
      let(:update_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "creators" => creators,
            },
          },
        }
      end

      it "updates the Doi" do
        patch "/dois/#{doi.doi}?affiliation=true", update_attributes, headers

        expect(json.dig("data", "attributes", "creators")).to eq(creators)

        doc = Nokogiri::XML(Base64.decode64(json.dig("data", "attributes", "xml")), nil, "UTF-8", &:noblanks)
        expect(doc.at_css("creators", "creator").to_s + "\n").to eq(
          <<~HEREDOC,
            <creators>
              <creator>
                <creatorName>Ollomi, Benjamin</creatorName>
                <affiliation>Cambridge University</affiliation>
                <affiliation>EMBL-EBI</affiliation>
              </creator>
            </creators>
          HEREDOC
        )
      end
    end

    context "remove series_information" do
      let(:xml) { File.read(file_fixture("datacite_series_information.xml")) }
      let(:descriptions) do
        [{ "description" => "Axel is a minimalistic cliff climbing rover that can explore
        extreme terrains from the moon, Mars, and beyond. To
        increase the technology readiness and scientific usability
        of Axel, a sampling system needs to be designed and
        build for sampling different rock and soils. To decrease
        the amount of force required to sample clumpy and
        possibly icy science targets, a percussive scoop could be
        used. A percussive scoop uses repeated impact force to
        dig into samples and a rotary actuation to collect the
        samples. Percussive scooping can reduce the amount of downward force required by about two to four
        times depending on the cohesion of the soil and the depth of the sampling. The goal for this project is to
        build a working prototype of a percussive scoop for Axel.", "descriptionType" => "Abstract" }]
      end
      let(:doi) { create(:doi, client: client, doi: "10.14454/05mb-q396", url: "https://example.org", xml: xml, event: "publish", related_items: nil) }
      let(:update_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "descriptions" => descriptions,
            },
          },
        }
      end

      it "updates the Doi" do
        patch "/dois/#{doi.doi}", update_attributes, headers

        expect(json.dig("data", "attributes", "descriptions")).to eq(descriptions)
        expect(json.dig("data", "attributes", "container")).to be_empty
      end
    end

    context "remove series_information via xml", elasticsearch: true do
      let(:xml) { Base64.strict_encode64(File.read(file_fixture("datacite_series_information.xml"))) }
      let(:xml_new) { Base64.strict_encode64(File.read(file_fixture("datacite_no_series_information.xml"))) }
      let!(:doi) { create(:doi, client: client, doi: "10.14454/05mb-q396", url: "https://datacite.org", event: "publish", related_items: nil) }
      let(:update_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "xml" => xml,
            },
          },
        }
      end
      let(:update_attributes_again) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "xml" => xml_new,
            },
          },
        }
      end

      before do
        DataciteDoi.import
        sleep 2
      end

      it "updates the Doi" do
        get "/dois/#{doi.doi}", nil, headers

        expect(json.dig("data", "attributes", "descriptions")).to eq([{ "description" => "Data from: A new malaria agent in African hominids.", "descriptionType" => "TechnicalInfo" }])
        expect(json.dig("data", "attributes", "container")).to be_empty

        patch "/dois/#{doi.doi}", update_attributes, headers

        expect(json.dig("data", "attributes", "descriptions").size).to eq(2)
        expect(json.dig("data", "attributes", "titles", 0, "title")).to eq("Percussive Scoop Sampling in Extreme Terrain")
        expect(json.dig("data", "attributes", "descriptions").last).to eq("description" => "Keck Institute for Space Studies", "descriptionType" => "SeriesInformation")
        expect(json.dig("data", "attributes", "container")).to eq("title" => "Keck Institute for Space Studies", "type" => "Series")

        patch "/dois/#{doi.doi}", update_attributes_again, headers

        expect(json.dig("data", "attributes", "descriptions").size).to eq(1)
        expect(json.dig("data", "attributes", "container")).to be_empty
      end
    end

    context "landing page" do
      let(:url) { "https://blog.datacite.org/re3data-science-europe/" }
      let(:xml) { Base64.strict_encode64(file_fixture("datacite.xml").read) }
      let(:landing_page) do
        {
          "checked" => Time.zone.now.utc.iso8601,
          "status" => 200,
          "url" => url,
          "contentType" => "text/html",
          "error" => nil,
          "redirectCount" => 0,
          "redirectUrls" => [],
          "downloadLatency" => 200,
          "hasSchemaOrg" => true,
          "schemaOrgId" => "10.14454/10703",
          "dcIdentifier" => nil,
          "citationDoi" => nil,
          "bodyHasPid" => true,
        }
      end
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "doi" => "10.14454/10703",
              "url" => url,
              "xml" => xml,
              "landingPage" => landing_page,
              "event" => "publish",
            },
          },
        }
      end

      it "creates a doi" do
        post "/dois", valid_attributes.to_json, { "HTTP_ACCEPT" => "application/vnd.api+json", "CONTENT_TYPE" => "application/vnd.api+json", "HTTP_AUTHORIZATION" => "Bearer " + bearer }

        expect(last_response.status).to eq(201)
        expect(json.dig("data", "attributes", "url")).to eq(url)
        expect(json.dig("data", "attributes", "doi")).to eq("10.14454/10703")
        expect(json.dig("data", "attributes", "landingPage")).to eq(landing_page)
        expect(json.dig("data", "attributes", "state")).to eq("findable")
      end

      it "fails to create a doi with bad data" do
        valid_attributes["data"]["attributes"]["landingPage"] = "http://example.com"
        post "/dois", valid_attributes.to_json, { "HTTP_ACCEPT" => "application/vnd.api+json", "CONTENT_TYPE" => "application/vnd.api+json", "HTTP_AUTHORIZATION" => "Bearer " + bearer }

        expect(last_response.status).to eq(422)
      end
    end

    context "update with landing page info as admin" do
      let(:url) { "https://blog.datacite.org/re3data-science-europe/" }
      let(:doi) { create(:doi, doi: "10.14454/10703", url: url, client: client) }
      let(:landing_page) do
        {
          "checked" => Time.zone.now.utc.iso8601,
          "status" => 200,
          "url" => url,
          "contentType" => "text/html",
          "error" => nil,
          "redirectCount" => 0,
          "redirectUrls" => [],
          "downloadLatency" => 200,
          "hasSchemaOrg" => true,
          "schemaOrgId" => "10.14454/10703",
          "dcIdentifier" => nil,
          "citationDoi" => nil,
          "bodyHasPid" => true,
        }
      end
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "landingPage" => landing_page,
              "event" => "publish",
            },
          },
        }
      end

      it "creates a doi" do
        put "/dois/#{doi.doi}", valid_attributes.to_json, { "HTTP_ACCEPT" => "application/vnd.api+json", "CONTENT_TYPE" => "application/vnd.api+json", "HTTP_AUTHORIZATION" => "Bearer " + admin_bearer }

        expect(last_response.status).to eq(200)
        expect(json.dig("data", "attributes", "doi")).to eq("10.14454/10703")
        expect(json.dig("data", "attributes", "landingPage")).to eq(landing_page)
        expect(json.dig("data", "attributes", "state")).to eq("findable")
      end
    end

    context "landing page schema-org-id array" do
      let(:url) { "https://blog.datacite.org/re3data-science-europe/" }
      let(:xml) { Base64.strict_encode64(file_fixture("datacite.xml").read) }
      let(:landing_page) do
        {
          "checked" => Time.zone.now.utc.iso8601,
          "status" => 200,
          "url" => url,
          "contentType" => "text/html",
          "error" => nil,
          "redirectCount" => 0,
          "redirectUrls" => [],
          "downloadLatency" => 200,
          "hasSchemaOrg" => true,
          "schemaOrgId" => [
            "http://dx.doi.org/10.4225/06/564AB348340D5",
          ],
          "dcIdentifier" => nil,
          "citationDoi" => nil,
          "bodyHasPid" => true,
        }
      end
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "doi" => "10.14454/10703",
              "url" => url,
              "xml" => xml,
              "landingPage" => landing_page,
              "event" => "publish",
            },
          },
        }
      end

      it "creates a Doi" do
        post "/dois", valid_attributes.to_json, { "HTTP_ACCEPT" => "application/vnd.api+json", "CONTENT_TYPE" => "application/vnd.api+json", "HTTP_AUTHORIZATION" => "Bearer " + bearer }

        expect(last_response.status).to eq(201)
        expect(json.dig("data", "attributes", "url")).to eq(url)
        expect(json.dig("data", "attributes", "doi")).to eq("10.14454/10703")
        expect(json.dig("data", "attributes", "landingPage")).to eq(landing_page)
        expect(json.dig("data", "attributes", "state")).to eq("findable")
      end
    end

    context "when the request is valid - crossref xml" do
      let(:xml) { Base64.strict_encode64(file_fixture("datacite-crossref.xml").read) }
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "doi" => "10.14454/10704",
              "url" => "http://www.bl.uk/pdf/patspec.pdf",
              "xml" => xml,
              "source" => "test",
              "event" => "publish",
            },
          },
        }
      end

      it "creates a Doi from valid crossref xml - testing contributors" do
        post "/dois", valid_attributes, headers

        expect(last_response.status).to eq(201)
        expect(json.dig("data", "attributes", "url")).to eq("http://www.bl.uk/pdf/patspec.pdf")
        expect(json.dig("data", "attributes", "doi")).to eq("10.14454/10704")
        expect(json.dig("data", "attributes", "titles")).to eq([{ "title" => "Proceedings of the Ocean Drilling Program, 180 Initial Reports" }])

        expect(json.dig("data", "attributes", "contributors")).to eq(
          [
            {
              "nameType" => "Personal",
              "name" => "Taylor, B.",
              "givenName" => "B.",
              "familyName" => "Taylor",
              "contributorType" => "Editor",
              "affiliation" => [],
              "nameIdentifiers" => []
            },
            {
              "nameType" => "Personal",
              "name" => "Huchon, P.",
              "givenName" => "P.",
              "familyName" => "Huchon",
              "contributorType" => "Editor",
              "affiliation" => [],
              "nameIdentifiers" => []
            },
            {
              "nameType" => "Personal",
              "name" => "Klaus, A.",
              "givenName" => "A.",
              "familyName" => "Klaus",
              "contributorType" => "Editor",
              "affiliation" => [],
              "nameIdentifiers" => []
            },
            {
              "nameType" => "Organizational",
              "name" => "et al.",
              "contributorType" => "Editor",
              "affiliation" => [],
              "nameIdentifiers" => []
            }
          ]
        )
        expect(json.dig("data", "attributes", "schemaVersion")).to eq("http://datacite.org/schema/kernel-4")
        expect(json.dig("data", "attributes", "source")).to eq("test")
        expect(json.dig("data", "attributes", "types")).to eq("schemaOrg" => "Book", "citeproc" => "book", "bibtex" => "book", "ris" => "BOOK", "resourceTypeGeneral" => "Book", "resourceType" => "Book")
        expect(json.dig("data", "attributes", "state")).to eq("findable")

        doc = Nokogiri::XML(Base64.decode64(json.dig("data", "attributes", "xml")), nil, "UTF-8", &:noblanks)
        expect(doc.at_css("identifier").content).to eq("10.14454/10704")
      end
    end
  end

# json-schema testing

  describe "POST /dois - json-schema" do
    let(:valid_attributes) do
      {
        "data" => {
          "type" => "dois",
          "attributes" => {
            "doi" => "10.14454/10703",
            "url" => "http://www.bl.uk/pdf/patspec.pdf",
            "types" => { "bibtex" => "article", "citeproc" => "article-journal", "resourceType" => "BlogPosting", "resourceTypeGeneral" => "Text", "ris" => "RPRT", "schemaOrg" => "ScholarlyArticle" },
            "titles" => [{ "title" => "Eating your own Dog Food" }],
            "publisher" => "DataCite",
            "publicationYear" => 2016,
            "creators" => [{ "familyName" => "Fenner", "givenName" => "Martin", "nameIdentifiers" => [{ "nameIdentifier" => "https://orcid.org/0000-0003-1419-2405", "nameIdentifierScheme" => "ORCID", "schemeUri" => "https://orcid.org" }], "name" => "Fenner, Martin", "nameType" => "Personal" }],
            "language" => "en",
            "alternateIdentifiers" => [{ "alternateIdentifier" => "123", "alternateIdentifierType" => "Repository ID" }],
            "rightsList" => [{ "rights" => "Creative Commons Attribution 3.0", "rightsUri" => "http://creativecommons.org/licenses/by/3.0/", "lang" => "en" }],
            "sizes" => ["4 kB", "12.6 MB"],
            "formats" => ["application/pdf", "text/csv"],
            "version" => "1.1",
            "fundingReferences" => [{ "funderIdentifier" => "https://doi.org/10.13039/501100009053", "funderIdentifierType" => "Crossref Funder ID", "funderName" => "The Wellcome Trust DBT India Alliance" }],
            "source" => "test",
            "event" => "publish",
            "relatedItems" => [{
              "contributors" => [{ "name" => "Smithson, James",
                                    "contributorType" => "ProjectLeader",
                                    "givenName" => "James",
                                    "familyName" => "Smithson",
                                    "nameType" => "Personal"
                                  }],
              "creators" => [{ "name" => "Smith, John",
                                "nameType" => "Personal",
                                "givenName" => "John",
                                "familyName" => "Smith",
                              }],
              "firstPage" => "249",
              "lastPage" => "264",
              "publicationYear" => "2018",
              "relatedItemIdentifier" => { "relatedItemIdentifier" => "10.1016/j.physletb.2017.11.044",
                                            "relatedItemIdentifierType" => "DOI",
                                            "relatedMetadataScheme" => "citeproc+json",
                                            "schemeURI" => "https://github.com/citation-style-language/schema/raw/master/csl-data.json",
                                            "schemeType" => "URL"
                                          },
              "relatedItemType" => "Journal",
              "relationType" => "HasMetadata",
              "titles" => [{ "title" => "Physics letters / B" }],
              "volume" => "776"
            }],
          },
        },
      }
    end

    before do
      VCR.eject_cassette
      VCR.turn_off!
      WebMock.allow_net_connect!
    end

    context "json-schema - validate language field - VALID" do
      before do
        valid_attributes["data"]["attributes"]["language"] = "fr"
      end

      it "creates a Doi" do
        puts "--------------------------"
        puts "LANGUAGE IS:"
        puts valid_attributes["data"]["attributes"]["language"]
        puts "--------------------------"

        VCR.turned_off do
          post "/dois", valid_attributes, headers
        end

        expect(last_response.status).to eq(201)
      end
    end

    context "json-schema - validate language field - INVALID" do
      before do
        valid_attributes["data"]["attributes"]["language"] = "fr!800-afs"
      end

      it "creates a Doi" do
        puts "--------------------------"
        puts "LANGUAGE IS:"
        puts valid_attributes["data"]["attributes"]["language"]
        puts "--------------------------"

        VCR.turned_off do
          post "/dois", valid_attributes, headers
        end

        puts "--------------------------"
        puts "ERRORS ARE:"
        puts json.dig("errors")
        puts "--------------------------"

        expect(last_response.status).to eq(422)
        expect(json.dig("errors")).to eq([
          {"source"=>"metadata", "title"=>"Is invalid", "uid"=>"10.14454/10703"}
        ])
      end
    end
  end
end
