# frozen_string_literal: true

require "rails_helper"
require "pp"
require "byebug"
include Passwordable

describe DataciteDoisController, type: :request do

  before(:all) do
    VCR.turn_off!
    WebMock.allow_net_connect!
  end

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

    context "when the request is valid with valid geoLocation properties - geoLocationPlace - json" do
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
                  "geoLocationPlace" => "New York, NY"
                }
              ],
              "source" => "test",
              "event" => "publish",
            },
          },
        }
      end

      it "creates a Doi - with geoLocation properties - geoLocationPlace" do
        VCR.turned_off do
          post "/dois", valid_attributes, headers
        end

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
        expect(json.dig("data", "attributes", "geoLocations")).to eq([{ "geoLocationPlace" => "New York, NY" }])
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
        expect(doc.at_css("geoLocations").content).to eq("New York, NY")
      end
    end

    context "when the request is valid with valid geoLocation properties - geoLocationPoint - json" do
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
                  "geoLocationPoint" => 
                    {
                      "pointLatitude" => "49.0850736",
                      "pointLongitude" => "-123.3300992"
                    }
                }
              ],
              "source" => "test",
              "event" => "publish",
            },
          },
        }
      end

      it "creates a Doi - with geoLocation properties - geoLocationPoint", :allow_real_requests do
        VCR.turned_off do
          post "/dois", valid_attributes, headers
        end
        
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
        expect(json.dig("data", "attributes", "geoLocations")).to eq([{
          "geoLocationPoint" => { "pointLatitude" => 49.0850736, "pointLongitude" => -123.3300992 }
        }])
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

    context "when the request is valid with valid geoLocation properties - geoLocationBox - json" do
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
              "geoLocations" => [{
                    "geoLocationBox" => {
                        "eastBoundLongitude" => "+123.",
                        "northBoundLatitude" => 60.2312,
                        "southBoundLatitude" => "-40",
                        "westBoundLongitude" => "-123.0"
                    }
               }],
              "source" => "test",
              "event" => "publish",
            },
          },
        }
      end

      it "creates a Doi - with geoLocation properties - geoLocationBox" do
        VCR.turned_off do
          post "/dois", valid_attributes, headers
        end

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
        expect(json.dig("data", "attributes", "geoLocations")).to eq([
          {
            "geoLocationBox" => {
                        "eastBoundLongitude" => +123.0,
                        "northBoundLatitude" => 60.2312,
                        "southBoundLatitude" => -40,
                        "westBoundLongitude" => -123.0
            }
          }
        ])
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
        expect(doc.at_css("geoLocations").content).to eq("-123.0+123.-4060.2312")
      end
    end

    context "when the request is valid with valid geoLocation properties - geoLocationPolygon - no inPolygonPoint - json" do
=begin
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
                  "geoLocationPolygon" => [
                    {
                      "polygonPoint" => {
                        "pointLatitude" => "42.4935265",
                        "pointLongitude" => "-87.812664"
                      }
                    },
                    {
                      "polygonPoint" => {
                        "pointLatitude" => "42.4975767",
                        "pointLongitude" => "-88.5872001"
                      }
                    },
                    {
                      "polygonPoint" => {
                        "pointLatitude" => 41.5550023,
                        "pointLongitude" => -88.6915703
                      }
                    },
                    {
                      "polygonPoint" => {
                        "pointLatitude" => 41.4624467,
                        "pointLongitude" => -87.5270195
                      }
                    },
                                {
                      "polygonPoint" => {
                        "pointLatitude" => 41.46244679,
                        "pointLongitude" => -87.51054
                      }
                    },
                    {
                      "polygonPoint" => {
                      "pointLatitude" => 42.4935265,
                      "pointLongitude" => -87.812664
                      }
                    },
                    {
                      "inPolygonPoint" => {
                        "pointLatitude" => "42.2195267",
                        "pointLongitude" => "-88.2960624"
                      }
                    }
                  ]
                }
              ],
              "source" => "test",
              "event" => "publish",
            },
          },
        }
      end
=end

      let(:valid_attributes) do
        {
            "data" => {
                "type" => "dois",
                "attributes" => {
                    "doi" => "10.14454/00000002",
                    "url" => "https://example.org",                            
                    "creators" => [{ "familyName" => "Vogt", "givenName" => "Sarah", "nameIdentifiers" => [], "name" => "Vogt, Sarah", "Sarah" => "Personal" }],

                    "titles" => [{ "title" => "Test Title" }],
                    "publisher" => {
                        "name" => "University of Illinois Urbana-Champaign",
                        "lang" => "en",
                        "publisherIdentifier" => "https://ror.org/047426m28",
                        "publisherIdentifierScheme" => "ROR",
                        "schemeUri" => "https://ror.org"
                    },
                    "publicationYear" => 2025,
                    "subjects" => [],
                    "contributors" => [{ "contributorType" => "DataManager", "familyName" => "Vogt", "givenName" => "Sarah", "nameIdentifiers" => [], "name" => "Vogt, Sarah", "nameType" => "Personal" }],
                    "alternateIdentifiers" => [],
                    "dates" => [],
                    "language" => "french",
                    "types" => {
                        "resourceTypeGeneral" => "Dataset"
                    },
                    "relatedIdentifiers" => [],
                    "sizes" => [],
                    "formats" => [],
                    "rightsList" => [],
                    "descriptions" => [],
                    "geoLocations" => [
                        {
                            "geoLocationPlace" => "New York, NY",
                            "geoLocationPoint" => {
                                "pointLatitude" => 31.233,
                                "pointLongitude" => "-67.302"
                            },
                            "geoLocationBox" => {
                                "eastBoundLongitude" => "+123.",
                                "northBoundLatitude" => 60.2312,
                                "southBoundLatitude" => "-40",
                                "westBoundLongitude" => "-123.0"
                            },
                            "geoLocationPolygon" => [
                                {
                                    "polygonPoint" => {
                                        "pointLatitude" => 42.4935265,
                                        "pointLongitude" => -87.812664
                                    }
                                },
                                {
                                    "polygonPoint" => {
                                        "pointLatitude" => 42.4975767,
                                        "pointLongitude" => -88.5872001
                                    }
                                },
                                {
                                    "polygonPoint" => {
                                        "pointLatitude" => 41.5550023,
                                        "pointLongitude" => -88.6915703
                                    }
                                },
                                {
                                    "polygonPoint" => {
                                        "pointLatitude" => 41.4624467,
                                        "pointLongitude" => -87.5270195
                                    }
                                },
                                                        {
                                    "polygonPoint" => {
                                        "pointLatitude" => 41.46244679,
                                        "pointLongitude" => -87.51054
                                    }
                                },
                                {
                                    "polygonPoint" => {
                                        "pointLatitude" => 42.2012176,
                                        "pointLongitude" => -87.812664
                                    }
                                },
                                {
                                    "inPolygonPoint" => {
                                        "pointLatitude" => 42.2195267,
                                        "pointLongitude" => -88.2960624
                                    }
                                }
                            ]
                        }
                    ],
                    "fundingReferences" => [],
                    "relatedItems" => [],
                    "schemaVersion" => "http://datacite.org/schema/kernel-4",
                    "source" => "test",
                    "event" => "publish"
                }
            }
        }
      end

      it "creates a Doi - with geoLocation properties - geoLocationPolygon - with inPolygonPoint - json" do
        VCR.turned_off do
          post "/dois", valid_attributes, headers
        end

=begin
        expect(json.dig("data", "attributes", "geoLocations")).to eq([
          {
              "geoLocationPlace" => "New York, NY",
              "geoLocationPoint" => {
                  "pointLatitude" => 31.233,
                  "pointLongitude" => "-67.302"
              },
              "geoLocationBox" => {
                  "eastBoundLongitude" => "+123.",
                  "northBoundLatitude" => 60.2312,
                  "southBoundLatitude" => "-40",
                  "westBoundLongitude" => "-123.0"
              },
              "geoLocationPolygon" => [
                  {
                      "polygonPoint" => {
                          "pointLatitude" => 42.4935265,
                          "pointLongitude" => -87.812664
                      }
                  },
                  {
                      "polygonPoint" => {
                          "pointLatitude" => 42.4975767,
                          "pointLongitude" => -88.5872001
                      }
                  },
                  {
                      "polygonPoint" => {
                          "pointLatitude" => 41.5550023,
                          "pointLongitude" => -88.6915703
                      }
                  },
                  {
                      "polygonPoint" => {
                          "pointLatitude" => 41.4624467,
                          "pointLongitude" => -87.5270195
                      }
                  },
                                          {
                      "polygonPoint" => {
                          "pointLatitude" => 41.46244679,
                          "pointLongitude" => -87.51054
                      }
                  },
                  {
                      "polygonPoint" => {
                          "pointLatitude" => 42.2012176,
                          "pointLongitude" => -87.812664
                      }
                  },
                  {
                      "inPolygonPoint" => {
                          "pointLatitude" => 42.2195267,
                          "pointLongitude" => -88.2960624
                      }
                  }
              ]
          }
        ])
=end
      end
    end
    
    context "when the request is valid with valid geoLocation properties - geoLocationPolygon" do
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "doi" => "10.14454/10703",
              "url" => "http://www.bl.uk/pdf/patspec.pdf",
              "xml" => "PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiPz4KPHJlc291cmNlIHhtbG5zOnhzaT0iaHR0cDovL3d3dy53My5vcmcvMjAwMS9YTUxTY2hlbWEtaW5zdGFuY2UiIHhtbG5zPSJodHRwOi8vZGF0YWNpdGUub3JnL3NjaGVtYS9rZXJuZWwtNCIgeHNpOnNjaGVtYUxvY2F0aW9uPSJodHRwOi8vZGF0YWNpdGUub3JnL3NjaGVtYS9rZXJuZWwtNCBodHRwOi8vc2NoZW1hLmRhdGFjaXRlLm9yZy9tZXRhL2tlcm5lbC00L21ldGFkYXRhLnhzZCI+CiAgPGlkZW50aWZpZXIgaWRlbnRpZmllclR5cGU9IkRPSSI+MTAuMTQ0NTQvNDlRNi1HSjk1PC9pZGVudGlmaWVyPgogIDxjcmVhdG9ycz4KICAgIDxjcmVhdG9yPgogICAgICA8Y3JlYXRvck5hbWU+U2FyYWggVm9ndDwvY3JlYXRvck5hbWU+CiAgICA8L2NyZWF0b3I+CiAgPC9jcmVhdG9ycz4KICA8dGl0bGVzPgogICAgPHRpdGxlPlRlc3QgVGl0bGU8L3RpdGxlPgogIDwvdGl0bGVzPgogIDxwdWJsaXNoZXIgcHVibGlzaGVySWRlbnRpZmllcj0iaHR0cHM6Ly9yb3Iub3JnLzA0NzQyNm0yOCIgcHVibGlzaGVySWRlbnRpZmllclNjaGVtZT0iUk9SIiBzY2hlbWVVUkk9Imh0dHBzOi8vcm9yLm9yZyI+VW5pdmVyc2l0eSBvZiBJbGxpbm9pcyBVcmJhbmEtQ2hhbXBhaWduPC9wdWJsaXNoZXI+CiAgPHB1YmxpY2F0aW9uWWVhcj4yMDI1PC9wdWJsaWNhdGlvblllYXI+CiAgPHJlc291cmNlVHlwZSByZXNvdXJjZVR5cGVHZW5lcmFsPSJEYXRhc2V0Ii8+CiAgPGNvbnRyaWJ1dG9ycz4KICAgIDxjb250cmlidXRvciBjb250cmlidXRvclR5cGU9IkRhdGFDdXJhdG9yIj4KICAgICAgPGNvbnRyaWJ1dG9yTmFtZT5ibGFoIHVuaXZlcnNpdHk8L2NvbnRyaWJ1dG9yTmFtZT4KICAgICAgPG5hbWVJZGVudGlmaWVyIG5hbWVJZGVudGlmaWVyU2NoZW1lPSIiIHNjaGVtZVVSST0iIi8+CiAgICAgIDxhZmZpbGlhdGlvbi8+CiAgICA8L2NvbnRyaWJ1dG9yPgogIDwvY29udHJpYnV0b3JzPgogIDxsYW5ndWFnZT5mcmVuY2g8L2xhbmd1YWdlPgogIDxzaXplcy8+CiAgPGZvcm1hdHMvPgogIDx2ZXJzaW9uLz4KICA8Z2VvTG9jYXRpb25zPgogICAgPGdlb0xvY2F0aW9uPgogICAgICA8Z2VvTG9jYXRpb25QbGFjZT5OZXcgWW9yaywgTlk8L2dlb0xvY2F0aW9uUGxhY2U+CiAgICAgIDxnZW9Mb2NhdGlvblBvaW50PgogICAgICAgIDxwb2ludExhdGl0dWRlPjMxLjIzMzwvcG9pbnRMYXRpdHVkZT4KICAgICAgICA8cG9pbnRMb25naXR1ZGU+LTY3LjMwMjwvcG9pbnRMb25naXR1ZGU+CiAgICAgIDwvZ2VvTG9jYXRpb25Qb2ludD4KICAgICAgPGdlb0xvY2F0aW9uQm94PgogICAgICAgIDx3ZXN0Qm91bmRMb25naXR1ZGU+LTEyMy4wPC93ZXN0Qm91bmRMb25naXR1ZGU+CiAgICAgICAgPGVhc3RCb3VuZExvbmdpdHVkZT4rMTIzLjwvZWFzdEJvdW5kTG9uZ2l0dWRlPgogICAgICAgIDxzb3V0aEJvdW5kTGF0aXR1ZGU+LTQwPC9zb3V0aEJvdW5kTGF0aXR1ZGU+CiAgICAgICAgPG5vcnRoQm91bmRMYXRpdHVkZT42MC4yMzEyPC9ub3J0aEJvdW5kTGF0aXR1ZGU+CiAgICAgIDwvZ2VvTG9jYXRpb25Cb3g+CiAgICAgIDxnZW9Mb2NhdGlvblBvbHlnb24+CiAgICAgICAgPHBvbHlnb25Qb2ludD4KICAgICAgICAgIDxwb2ludExhdGl0dWRlPjQyLjQ5MzUyNjU8L3BvaW50TGF0aXR1ZGU+CiAgICAgICAgICA8cG9pbnRMb25naXR1ZGU+LTg3LjgxMjY2NDwvcG9pbnRMb25naXR1ZGU+CiAgICAgICAgPC9wb2x5Z29uUG9pbnQ+CiAgICAgICAgPHBvbHlnb25Qb2ludD4KICAgICAgICAgIDxwb2ludExhdGl0dWRlPjQyLjQ5NzU3Njc8L3BvaW50TGF0aXR1ZGU+CiAgICAgICAgICA8cG9pbnRMb25naXR1ZGU+LTg4LjU4NzIwMDE8L3BvaW50TG9uZ2l0dWRlPgogICAgICAgIDwvcG9seWdvblBvaW50PgogICAgICAgIDxwb2x5Z29uUG9pbnQ+CiAgICAgICAgICA8cG9pbnRMYXRpdHVkZT40MS41NTUwMDIzPC9wb2ludExhdGl0dWRlPgogICAgICAgICAgPHBvaW50TG9uZ2l0dWRlPi04OC42OTE1NzAzPC9wb2ludExvbmdpdHVkZT4KICAgICAgICA8L3BvbHlnb25Qb2ludD4KICAgICAgICA8cG9seWdvblBvaW50PgogICAgICAgICAgPHBvaW50TGF0aXR1ZGU+NDEuNDYyNDQ2NzwvcG9pbnRMYXRpdHVkZT4KICAgICAgICAgIDxwb2ludExvbmdpdHVkZT4tODcuNTI3MDE5NTwvcG9pbnRMb25naXR1ZGU+CiAgICAgICAgPC9wb2x5Z29uUG9pbnQ+CiAgICAgICAgPHBvbHlnb25Qb2ludD4KICAgICAgICAgIDxwb2ludExhdGl0dWRlPjQxLjQ2MjQ0Njc5PC9wb2ludExhdGl0dWRlPgogICAgICAgICAgPHBvaW50TG9uZ2l0dWRlPi04Ny41MTA1NDwvcG9pbnRMb25naXR1ZGU+CiAgICAgICAgPC9wb2x5Z29uUG9pbnQ+CiAgICAgICAgPHBvbHlnb25Qb2ludD4KICAgICAgICAgIDxwb2ludExhdGl0dWRlPjQyLjIwMTIxNzY8L3BvaW50TGF0aXR1ZGU+CiAgICAgICAgICA8cG9pbnRMb25naXR1ZGU+LTg3LjgxMjY2NDwvcG9pbnRMb25naXR1ZGU+CiAgICAgICAgPC9wb2x5Z29uUG9pbnQ+CiAgICAgICAgPGluUG9seWdvblBvaW50PgogICAgICAgICAgPHBvaW50TGF0aXR1ZGU+NDIuMjE5NTI2NzwvcG9pbnRMYXRpdHVkZT4KICAgICAgICAgIDxwb2ludExvbmdpdHVkZT4tODguMjk2MDYyNDwvcG9pbnRMb25naXR1ZGU+CiAgICAgICAgPC9pblBvbHlnb25Qb2ludD4KICAgICAgPC9nZW9Mb2NhdGlvblBvbHlnb24+CiAgICA8L2dlb0xvY2F0aW9uPgogIDwvZ2VvTG9jYXRpb25zPgo8L3Jlc291cmNlPgo="
            }
          } 
        }
      end

      it "creates a Doi - with geoLocation properties - xml" do
        VCR.turned_off do
          post "/dois", valid_attributes, headers
        end

        expect(last_response.status).to eq(201)
      end


        # doc = Nokogiri::XML(Base64.decode64(json.dig("data", "attributes", "xml")), nil, "UTF-8", &:noblanks)
        # str = Base64.decode64(json.dig("data", "attributes", "xml"))
        # puts "XXXX STR:"
        # puts str
        # expect(doc.at_css("identifier").content).to eq("10.14454/10703")
        # expect(doc.at_css("subjects").content).to eq("80505 Web Technologies (excl. Web Search)")
        # expect(doc.at_css("contributors").content).to eq("Fenner, KurtKurtFennerhttps://orcid.org/0000-0003-1419-2401")
        # expect(doc.at_css("dates").content).to eq("2017-02-242015-11-282017-02-24")
        # expect(doc.at_css("relatedIdentifiers").content).to eq("10.5438/55e5-t5c0")
        # expect(doc.at_css("descriptions").content).to start_with("Diet and physical activity")
        # expect(doc.at_css("geoLocations").content).to eq("42.4935265-87.81266442.4975767-88.587200141.5550023-88.691570341.4624467-87.527019541.46244679-87.5105442.4935265-87.812664")
    end
  end
end
