# frozen_string_literal: true

require "rails_helper"

describe ProvidersController, type: :request, elasticsearch: true do
  let(:consortium) { create(:provider, role_name: "ROLE_CONSORTIUM") }
  let(:provider) do
    create(
      :provider,
      consortium: consortium, role_name: "ROLE_CONSORTIUM_ORGANIZATION",
    )
  end
  let(:token) do
    User.generate_token(
      role_id: "consortium_admin", provider_id: consortium.symbol.downcase,
    )
  end
  let(:admin_token) { User.generate_token }
  let(:params) do
    {
      "data" => {
        "type" => "providers",
        "attributes" => {
          "symbol" => "BL",
          "name" => "British Library",
          "displayName" => "British Library",
          "systemEmail" => "bob@example.com",
          "website" => "https://www.bl.uk",
          "country" => "GB",
        },
      },
    }
  end
  let(:headers) do
    {
      "HTTP_ACCEPT" => "application/vnd.api+json",
      "HTTP_AUTHORIZATION" => "Bearer " + token,
    }
  end
  let(:admin_headers) do
    {
      "HTTP_ACCEPT" => "application/vnd.api+json",
      "HTTP_AUTHORIZATION" => "Bearer " + admin_token,
    }
  end

  describe "GET /providers" do
    let!(:providers) { create_list(:provider, 3) }

    before do
      Provider.import
      sleep 2
    end

    it "returns providers" do
      get "/providers", nil, headers

      expect(last_response.status).to eq(200)
      expect(json["data"].size).to eq(3)
      expect(json.dig("meta", "total")).to eq(3)
    end
  end

  describe "GET /providers for consortium" do
    let(:consortium) do
      create(:provider, symbol: "dc", role_name: "ROLE_CONSORTIUM")
    end
    let!(:consortium_organization) do
      create(
        :provider,
        consortium: consortium, role_name: "ROLE_CONSORTIUM_ORGANIZATION",
      )
    end
    let!(:provider) { create(:provider) }

    before do
      Provider.import
      sleep 2
    end

    it "returns providers" do
      get "/providers?consortium-id=dc", nil, headers

      expect(last_response.status).to eq(200)
      expect(json["data"].size).to eq(1)
      expect(json.dig("meta", "total")).to eq(1)
    end
  end

  describe "GET /providers/:id" do
    context "when the record exists" do
      it "returns the provider" do
        get "/providers/#{provider.symbol.downcase}",
            nil, headers

        expect(last_response.status).to eq(200)
        expect(json["data"]["id"]).to eq(provider.symbol.downcase)
        expect(json["meta"]).to eq("repositoryCount" => 0)
      end

      it "returns the provider info for member page" do
        get "/providers/#{provider.symbol.downcase}",
            nil, headers

        expect(json["data"]["attributes"]["twitterHandle"]).to eq(
          provider.twitter_handle,
        )
        expect(json["data"]["attributes"]["billingInformation"]).to eq(
          provider.billing_information,
        )
        expect(json["data"]["attributes"]["rorId"]).to eq(provider.ror_id)
      end
    end

    context "get provider type ROLE_CONTRACTUAL_PROVIDER and check it works " do
      let(:provider) do
        create(
          :provider,
          role_name: "ROLE_CONTRACTUAL_PROVIDER",
          name: "Contractor",
          symbol: "CONTRCTR",
        )
      end

      it "get provider" do
        get "/providers/#{provider.symbol.downcase}",
            nil, headers

        expect(last_response.status).to eq(200)
        expect(json.dig("data", "id")).to eq(provider.symbol.downcase)
      end
    end

    context "when the record does not exist" do
      it "returns a not found message" do
        get "/providers/xxx", nil, headers

        expect(last_response.status).to eq(404)
        expect(json["errors"].first).to eq(
          "status" => "404",
          "title" => "The resource you are looking for doesn't exist.",
        )
      end
    end

    context "text/csv" do
      it "returns status code 200" do
        get "/providers/",
            nil,
            {
              "HTTP_ACCEPT" => "text/csv", "Authorization" => "Bearer " + token
            }

        expect(last_response.status).to eq(200)
      end
    end
  end

  describe "GET /providers/:id with contacts" do
    let!(:contact) { create(:contact, provider: provider, role_name: ["billing"]) }

    before do
      Provider.import
      Contact.import
      sleep 2
    end

    context "when the record exists" do
      it "returns the provider" do
        get "/providers/#{provider.symbol.downcase}?include=contacts",
            nil, headers

        expect(last_response.status).to eq(200)
        expect(json["data"]["id"]).to eq(provider.symbol.downcase)
        expect(json.dig("data", "relationships", "contacts", "data", 0)).to be_present
        expect(json.dig("included", 0, "attributes", "name")).to eq("Josiah Carberry")
        expect(json["meta"]).to eq("repositoryCount" => 0)
      end
    end
  end

  describe "GET /providers/:id meta" do
    let(:provider) { create(:provider) }
    let(:client) { create(:client, provider: provider) }
    let!(:dois) { create_list(:doi, 3, client: client, aasm_state: "findable") }

    before do
      Provider.import
      Client.import
      DataciteDoi.import
      sleep 2
    end

    it "returns provider" do
      get "/providers/#{provider.symbol.downcase}",
          nil, headers

      expect(last_response.status).to eq(200)
      expect(json.dig("data", "id")).to eq(provider.symbol.downcase)
      expect(json["meta"]).to eq("repositoryCount" => 1)
    end
  end

  describe "GET /providers/totals" do
    let(:provider) { create(:provider) }
    let(:dev) { create(:provider, role_name: "ROLE_DEV") }
    let(:client) { create(:client, provider: provider) }
    let!(:prefixes) { create_list(:prefix, 10) }
    let!(:dois) { create_list(:doi, 3, client: client, aasm_state: "findable") }

    before do
      Provider.import
      Client.import
      DataciteDoi.import
      sleep 2
    end

    it "returns providers" do
      get "/providers/totals", nil, headers

      expect(last_response.status).to eq(200)
      # expect(json['data'].size).to eq(4)
      expect(json.first.dig("count")).to eq(3)
      expect(json.first.dig("temporal")).not_to be_nil
    end
  end

  describe "GET /providers/:id/stats" do
    let(:provider) { create(:provider) }
    let(:client) { create(:client, provider: provider) }
    let!(:dois) do
      create_list(
        :doi,
        3,
        client: client, aasm_state: "findable", type: "DataciteDoi",
      )
    end

    before do
      Provider.import
      Client.import
      DataciteDoi.import
      sleep 2
    end

    it "returns provider" do
      get "/providers/#{provider.symbol.downcase}/stats",
          nil, headers

      current_year = Date.today.year.to_s
      expect(last_response.status).to eq(200)
      expect(json["clients"]).to eq(
        [{ "count" => 1, "id" => current_year, "title" => current_year }],
      )
      # expect(json["resourceTypes"]).to eq([{"count"=>3, "id"=>"dataset", "title"=>"Dataset"}])
      expect(json["dois"]).to eq(
        [{ "count" => 3, "id" => current_year, "title" => current_year }],
      )
    end
  end

  describe "POST /providers" do
    context "request is valid" do
      let(:logo) do
        "data:image/png;base64," +
          Base64.strict_encode64(file_fixture("bl.png").read)
      end
      let(:params) do
        {
          "data" => {
            "type" => "providers",
            "attributes" => {
              "symbol" => "BL",
              "name" => "British Library",
              "displayName" => "British Library",
              "memberType" => "consortium_organization",
              "logo" => logo,
              "website" => "https://www.bl.uk",
              "salesforceId" => "abc012345678901234",
              "region" => "EMEA",
              "systemEmail" => "doe@joe.joe",
              "country" => "GB",
            },
            "relationships": {
              "consortium": {
                "data": {
                  "type": "providers", "id": consortium.symbol.downcase
                },
              },
            },
          },
        }
      end

      it "creates a provider" do
        post "/providers", params, headers

        expect(last_response.status).to eq(200)
        expect(json.dig("data", "attributes", "name")).to eq("British Library")
        expect(json.dig("data", "attributes", "systemEmail")).to eq(
          "doe@joe.joe",
        )
        expect(
          json.dig("data", "relationships", "consortium", "data", "id"),
        ).to eq(consortium.symbol.downcase)
      end
    end

    context "from salesforce" do
      let(:params) do
        {
          "data" => {
            "type" => "providers",
            "attributes" => {
              "symbol" => "BL",
              "name" => "British Library",
              "displayName" => "British Library",
              "memberType" => "consortium_organization",
              "website" => "https://www.bl.uk",
              "salesforceId" => "abc012345678901234",
              "fromSalesforce" => true,
              "region" => "EMEA",
              "systemEmail" => "doe@joe.joe",
              "country" => "GB",
            },
            "relationships": {
              "consortium": {
                "data": {
                  "type": "providers", "id": consortium.symbol.downcase
                },
              },
            },
          },
        }
      end

      it "creates a provider" do
        post "/providers", params, headers

        expect(last_response.status).to eq(200)
        expect(json.dig("data", "attributes", "name")).to eq("British Library")
        expect(json.dig("data", "attributes", "fromSalesforce")).to eq(
          true
        )
      end
    end

    context "request ability check" do
      let!(:providers) { create_list(:provider, 2) }
      let(:last_provider_token) do
        User.generate_token(
          provider_id: providers.last.symbol, role_id: "provider_admin",
        )
      end
      let(:headers_last) do
        {
          "HTTP_ACCEPT" => "application/vnd.api+json",
          "HTTP_AUTHORIZATION" => "Bearer " + last_provider_token,
        }
      end

      before do
        Provider.import
        sleep 2
      end

      it "has no permission" do
        get "/providers/#{providers.first.symbol}",
            nil, headers_last

        expect(json["data"].dig("attributes", "symbol")).to eq(
          providers.first.symbol,
        )
        expect(json["data"].dig("attributes", "billingInformation")).to eq(nil)
        expect(json["data"].dig("attributes", "twitterHandle")).to eq(nil)
      end
    end

    context "create provider member_role contractual_member" do
      let(:params) do
        {
          "data" => {
            "type" => "providers",
            "attributes" => {
              "symbol" => "FG",
              "name" => "Figshare",
              "displayName" => "Figshare",
              "region" => "EMEA",
              "systemEmail" => "doe@joe.joe",
              "website" => "https://www.bl.uk",
              "memberType" => "contractual_member",
              "country" => "GB",
            },
          },
        }
      end

      it "creates a provider" do
        post "/providers", params, admin_headers

        expect(last_response.status).to eq(200)
        expect(json.dig("data", "attributes", "systemEmail")).to eq(
          "doe@joe.joe",
        )
        expect(json.dig("data", "attributes", "name")).to eq("Figshare")
        expect(json.dig("data", "attributes", "memberType")).to eq(
          "contractual_member",
        )
      end
    end

    context "create provider member_role consortium_organization" do
      let(:params) do
        {
          "data" => {
            "type" => "providers",
            "attributes" => {
              "symbol" => "FG",
              "name" => "Figshare",
              "displayName" => "Figshare",
              "region" => "EMEA",
              "systemEmail" => "doe@joe.joe",
              "website" => "https://www.bl.uk",
              "memberType" => "consortium_organization",
              "country" => "GB",
            },
            "relationships": {
              "consortium": {
                "data": {
                  "type": "providers", "id": consortium.symbol.downcase
                },
              },
            },
          },
        }
      end

      xit "creates a provider" do
        post "/providers", params, headers

        expect(last_response.status).to eq(200)
        expect(json.dig("data", "attributes", "systemEmail")).to eq(
          "doe@joe.joe",
        )
        expect(json.dig("data", "attributes", "name")).to eq("Figshare")
        expect(json.dig("data", "attributes", "memberType")).to eq(
          "consortium_organization",
        )
        expect(
          json.dig("data", "relationships", "consortium", "data", "id"),
        ).to eq(consortium.symbol.downcase)

        sleep 1

        get "/providers/#{
              consortium.symbol.downcase
            }?include=consortium-organizations",
            nil, headers

        expect(last_response.status).to eq(200)
        expect(json.dig("included", 0, "attributes", "systemEmail")).to eq(
          "doe@joe.joe",
        )
        expect(json.dig("included", 0, "attributes", "name")).to eq("Figshare")
        expect(json.dig("included", 0, "attributes", "memberType")).to eq(
          "consortium_organization",
        )
        expect(
          json.dig("included", 0, "relationships", "consortium", "data", "id"),
        ).to eq(consortium.symbol)

        # get "/providers?consortium-lead-id=#{consortium_lead.symbol.downcase}", nil, headers

        # expect(last_response.status).to eq(200)

        # get "/providers/#{consortium_lead.symbol.downcase}/organizations", nil, headers

        # expect(last_response.status).to eq(200)
      end
    end

    context "create provider not member_role consortium_organization" do
      let(:params) do
        {
          "data" => {
            "type" => "providers",
            "attributes" => {
              "symbol" => "FG",
              "name" => "Figshare",
              "displayName" => "Figshare",
              "region" => "EMEA",
              "systemEmail" => "doe@joe.joe",
              "memberType" => "provider",
              "website" => "https://www.bl.uk",
              "country" => "GB",
            },
            "relationships": {
              "consortium": {
                "data": {
                  "type": "providers", "id": consortium.symbol.downcase
                },
              },
            },
          },
        }
      end

      it "creates a provider" do
        post "/providers", params, headers

        expect(last_response.status).to eq(200)
        expect(json.dig("data", "attributes", "systemEmail")).to be_nil
        expect(json.dig("data", "attributes", "name")).to eq("Figshare")
        expect(json.dig("data", "attributes", "memberType")).to eq(
          "direct_member",
        )
        expect(
          json.dig("data", "relationships", "consortium", "data", "id"),
        ).to be_nil
      end
    end

    context "create provider not member_role consortium" do
      let(:params) do
        {
          "data" => {
            "type" => "providers",
            "attributes" => {
              "symbol" => "FG",
              "name" => "Figshare",
              "displayName" => "Figshare",
              "region" => "EMEA",
              "systemEmail" => "doe@joe.joe",
              "website" => "https://www.bl.uk",
              "memberType" => "consortium_organization",
              "country" => "GB",
            },
            "relationships": {
              "consortium": {
                "data": { "type": "providers", "id": provider.symbol.downcase },
              },
            },
          },
        }
      end

      it "creates a provider" do
        post "/providers", params, admin_headers

        expect(last_response.status).to eq(422)
        expect(json["errors"].first).to eq(
          "source" => "consortium_id",
          "title" => "The consortium must be of member_type consortium",
          "uid" => "fg"
        )
      end
    end

    context "request is valid with billing information" do
      let(:params) do
        {
          "data" => {
            "type" => "providers",
            "attributes" => {
              "systemEmail" => "jkiritha@andrew.cmu.edu",
              "country" => "US",
              "created" => "",
              "description" => "",
              "focusArea" => "general",
              "hasPassword" => "[FILTERED]",
              "isActive" => true,
              "joined" => "",
              "keepPassword" => "[FILTERED]",
              "logoUrl" => "",
              "website" => "https://www.bl.uk",
              "name" => "Carnegie Mellon University",
              "displayName" => "Carnegie Mellon University",
              "organizationType" => "academicInstitution",
              "passwordInput" => "[FILTERED]",
              "twitterHandle" => "@meekakitty",
              "rorId" => "https://ror.org/05njkjr15",
              "billingInformation": {
                "city" => "barcelona",
                "state" => "Rennes",
                "country" => "Rennes",
                "organization" => "Rennes",
                "department" => "Rennes",
                "address" => "Rennes",
                "postCode" => "122dc",
              },
              "region" => "",
              "symbol" => "CM",
              "updated" => "",
            },
          },
        }
      end

      it "creates a provider" do
        post "/providers", params, admin_headers

        expect(last_response.status).to eq(200)
        expect(json.dig("data", "attributes", "systemEmail")).to eq(
          "jkiritha@andrew.cmu.edu",
        )
        expect(
          json.dig("data", "attributes", "billingInformation", "state"),
        ).to eq("Rennes")
        expect(
          json.dig("data", "attributes", "billingInformation", "postCode"),
        ).to eq("122dc")
        expect(json.dig("data", "attributes", "twitterHandle")).to eq(
          "@meekakitty",
        )
        expect(json.dig("data", "attributes", "rorId")).to eq(
          "https://ror.org/05njkjr15",
        )
      end
    end

    context "request is valid with contact information" do
      let(:params) do
        {
          "data" => {
            "type" => "providers",
            "attributes" => {
              "systemEmail" => "jkiritha@andrew.cmu.edu",
              "country" => "US",
              "created" => "",
              "description" => "",
              "focusArea" => "general",
              "hasPassword" => "[FILTERED]",
              "isActive" => true,
              "joined" => "",
              "keepPassword" => "[FILTERED]",
              "logoUrl" => "",
              "name" => "Carnegie Mellon University",
              "displayName" => "Carnegie Mellon University",
              "organizationType" => "academicInstitution",
              "passwordInput" => "[FILTERED]",
              "twitterHandle" => "@eekakitty",
              "rorId" => "https://ror.org/05njkjr15",
              "technicalContact" => {
                "email" => "kristian@example.com",
                "givenName" => "Kristian",
                "familyName" => "Garza",
              },
              "serviceContact" => {
                "email" => "martin@example.com",
                "givenName" => "Martin",
                "familyName" => "Fenner",
              },
              "billingContact" => {
                "email" => "Trisha@example.com",
                "givenName" => "Trisha",
                "familyName" => "cruse",
              },
              "secondaryBillingContact" => {
                "email" => "Trisha@example.com",
                "givenName" => "Trisha",
                "familyName" => "cruse",
              },
              "votingContact" => {
                "email" => "robin@example.com",
                "givenName" => "Robin",
                "familyName" => "Dasler",
              },
              "region" => "",
              "symbol" => "CM",
              "updated" => "",
            },
          },
        }
      end

      it "creates a provider" do
        post "/providers", params, admin_headers

        expect(last_response.status).to eq(200)
        expect(
          json.dig("data", "attributes", "technicalContact", "email"),
        ).to eq("kristian@example.com")
        expect(
          json.dig("data", "attributes", "technicalContact", "givenName"),
        ).to eq("Kristian")
        expect(
          json.dig("data", "attributes", "technicalContact", "familyName"),
        ).to eq("Garza")
        expect(json.dig("data", "attributes", "billingContact", "email")).to eq(
          "Trisha@example.com",
        )
        expect(
          json.dig("data", "attributes", "billingContact", "givenName"),
        ).to eq("Trisha")
        expect(
          json.dig("data", "attributes", "billingContact", "familyName"),
        ).to eq("cruse")
        expect(
          json.dig("data", "attributes", "secondaryBillingContact", "email"),
        ).to eq("Trisha@example.com")
        expect(
          json.dig(
            "data",
            "attributes",
            "secondaryBillingContact",
            "givenName",
          ),
        ).to eq("Trisha")
        expect(
          json.dig(
            "data",
            "attributes",
            "secondaryBillingContact",
            "familyName",
          ),
        ).to eq("cruse")
        expect(json.dig("data", "attributes", "serviceContact", "email")).to eq(
          "martin@example.com",
        )
        expect(
          json.dig("data", "attributes", "serviceContact", "givenName"),
        ).to eq("Martin")
        expect(
          json.dig("data", "attributes", "serviceContact", "familyName"),
        ).to eq("Fenner")
        expect(json.dig("data", "attributes", "votingContact", "email")).to eq(
          "robin@example.com",
        )
        expect(
          json.dig("data", "attributes", "votingContact", "givenName"),
        ).to eq("Robin")
        expect(
          json.dig("data", "attributes", "votingContact", "familyName"),
        ).to eq("Dasler")
      end
    end

    context "request for admin provider with meta" do
      let(:params) do
        {
          "data" => {
            "attributes" => {
              "meta" => {
                "clients" => [
                  { "id" => "2019", "title" => "2019", "count" => 1 },
                ],
                "dois" => [],
              },
              "name" => "Carnegie Mellon University",
              "displayName" => "Carnegie Mellon University",
              "symbol" => "CMU",
              "description" => nil,
              "region" => "AMER",
              "country" => "US",
              "organizationType" => "academicInstitution",
              "focusArea" => "general",
              "logoUrl" => "",
              "systemEmail" => "jkiritha@andrew.cmu.edu",
              "isActive" => true,
              "passwordInput" => "@change",
              "hasPassword" => false,
              "keepPassword" => false,
              "joined" => "",
            },
            "type" => "providers",
          },
        }
      end

      it "creates a provider" do
        post "/providers", params, admin_headers

        expect(last_response.status).to eq(200)
        expect(json.dig("data", "attributes", "systemEmail")).to eq(
          "jkiritha@andrew.cmu.edu",
        )
      end
    end

    context "request for admin provider" do
      let(:params) do
        {
          "data" => {
            "type" => "providers",
            "attributes" => {
              "symbol" => "ADMIN",
              "name" => "Admin",
              "displayName" => "Admin",
              "region" => "EMEA",
              "systemEmail" => "doe@joe.joe",
              "country" => "GB",
            },
          },
        }
      end

      it "creates a provider" do
        post "/providers", params, admin_headers

        expect(last_response.status).to eq(200)
        expect(json.dig("data", "attributes", "systemEmail")).to eq(
          "doe@joe.joe",
        )
      end
    end

    context "request uses basic auth" do
      let(:params) do
        {
          "data" => {
            "type" => "providers",
            "attributes" => {
              "symbol" => "BL",
              "name" => "British Library",
              "displayName" => "British Library",
              "website" => "https://www.bl.uk",
              "region" => "EMEA",
              "systemEmail" => "doe@joe.joe",
              "country" => "GB",
            },
          },
        }
      end
      let(:admin) do
        create(
          :provider,
          symbol: "ADMIN", role_name: "ROLE_ADMIN", password_input: "12345",
        )
      end
      let(:credentials) do
        admin.encode_auth_param(username: "ADMIN", password: "12345")
      end
      let(:headers) do
        {
          "HTTP_ACCEPT" => "application/vnd.api+json",
          "HTTP_AUTHORIZATION" => "Basic " + credentials,
        }
      end

      xit "creates a provider" do
        post "/providers", params, headers

        expect(last_response.status).to eq(200)
        expect(json.dig("data", "attributes", "systemEmail")).to eq(
          "doe@joe.joe",
        )
      end
    end

    context "generate random symbol" do
      let(:params) do
        {
          "data" => {
            "type" => "providers",
            "attributes" => {
              "name" => "Admin",
              "displayName" => "Admin",
              "region" => "EMEA",
              "systemEmail" => "doe@joe.joe",
              "country" => "GB",
            },
          },
        }
      end

      it "creates a provider" do
        post "/providers", params, admin_headers

        expect(last_response.status).to eq(200)
        expect(json.dig("data", "attributes", "symbol")).to match(
          /\A[A-Z]{4}\Z/,
        )
      end
    end

    context "create provider with internationalOrganization organization type" do
      provider_symbol = "FG"
      let(:params) do
        {
          "data" => {
            "type" => "providers",
            "attributes" => {
              "symbol" => provider_symbol,
              "name" => "Figshare",
              "displayName" => "Figshare",
              "region" => "EMEA",
              "systemEmail" => "doe@joe.joe",
              "website" => "https://www.bl.uk",
              "memberType" => "direct_member",
              "organizationType" => "internationalOrganization",
              "country" => "GB",
            },
          },
        }
      end

      it "creates a provider" do
        post "/providers", params, admin_headers

        expect(last_response.status).to eq(200)
        expect(json.dig("data", "attributes", "organizationType")).to eq(
          "internationalOrganization",
        )

        sleep 1

        get "/providers/#{
              provider_symbol
            }",
            nil, headers

        expect(json.dig("data", "attributes", "organizationType")).to eq(
          "internationalOrganization",
        )
      end
    end

    context "when the request is missing a required attribute" do
      let(:params) do
        {
          "data" => {
            "type" => "providers",
            "attributes" => {
              "symbol" => "BL",
              "name" => "British Library",
              "displayName" => "British Library",
              "website" => "https://www.bl.uk",
              "country" => "GB",
            },
          },
        }
      end

      it "returns a validation failure message" do
        post "/providers", params, admin_headers

        expect(last_response.status).to eq(422)
        expect(json["errors"].first).to eq(
          "source" => "system_email", "title" => "Can't be blank",
          "uid" => "bl"
        )
      end
    end

    context "when the request is missing a data object" do
      let(:params) do
        {
          "type" => "providers",
          "attributes" => {
            "symbol" => "BL",
            "systemEmail" => "timAus",
            "name" => "British Library",
            "displayName" => "British Library",
            "website" => "https://www.bl.uk",
            "country" => "GB",
          },
        }
      end

      it "returns status code 400" do
        post "/providers", params, admin_headers

        expect(last_response.status).to eq(400)
      end

      # it 'returns a validation failure message' do
      #   expect(response["exception"]).to eq("#<JSON::ParserError: You need to provide a payload following the JSONAPI spec>")
      # end
    end
  end

  describe "PUT /providers/:id" do
    context "when the record exists" do
      let(:params) do
        {
          "data" => {
            "type" => "providers",
            "attributes" => {
              "name" => "British Library",
              "globusUuid" => "9908a164-1e4f-4c17-ae1b-cc318839d6c8",
              "displayName" => "British Library",
              "memberType" => "consortium_organization",
              "organizationType" => "internationalOrganization",
              "website" => "https://www.bl.uk",
              "region" => "Americas",
              "systemEmail" => "Pepe@mdm.cod",
              "country" => "GB",
            },
            "relationships": {
              "consortium": {
                "data": {
                  "type": "providers", "id": consortium.symbol.downcase
                },
              },
            },
          },
        }
      end

      it "updates the record" do
        put "/providers/#{provider.symbol}", params, headers

        expect(last_response.status).to eq(200)
        expect(json.dig("data", "attributes", "displayName")).to eq(
          "British Library",
        )
        expect(json.dig("data", "attributes", "globusUuid")).to eq(
          "9908a164-1e4f-4c17-ae1b-cc318839d6c8",
        )
        expect(
          json.dig("data", "relationships", "consortium", "data", "id"),
        ).to eq(consortium.symbol.downcase)
        expect(json.dig("data", "attributes", "organizationType")).to eq(
          "internationalOrganization",
        )
      end
    end

    context "when updating as consortium" do
      let(:consortium_credentials) do
        User.encode_auth_param(username: consortium.symbol, password: "12345")
      end
      let(:consortium_headers) do
        {
          "HTTP_ACCEPT" => "application/vnd.api+json",
          "HTTP_AUTHORIZATION" => "Basic " + consortium_credentials,
        }
      end
      let(:params) do
        {
          "data" => {
            "type" => "providers",
            "attributes" => {
              "name" => "British Library",
              "globusUuid" => "9908a164-1e4f-4c17-ae1b-cc318839d6c8",
              "displayName" => "British Library",
              "memberType" => "consortium_organization",
              "website" => "https://www.bl.uk",
              "region" => "Americas",
              "systemEmail" => "Pepe@mdm.cod",
              "country" => "GB",
            },
            "relationships": {
              "consortium": {
                "data": {
                  "type": "providers", "id": consortium.symbol.downcase
                },
              },
            },
          },
        }
      end

      xit "updates the record" do
        put "/providers/#{provider.symbol}",
            params, consortium_headers
        puts consortium_headers
        expect(last_response.status).to eq(200)
        expect(json.dig("data", "attributes", "displayName")).to eq(
          "British Library",
        )
        expect(json.dig("data", "attributes", "globusUuid")).to eq(
          "9908a164-1e4f-4c17-ae1b-cc318839d6c8",
        )
        expect(
          json.dig("data", "relationships", "consortium", "data", "id"),
        ).to eq(consortium.symbol.downcase)
      end
    end

    context "when updating as consortium_organization" do
      let(:consortium_organization_credentials) do
        User.encode_auth_param(username: provider.symbol, password: "12345")
      end
      let(:consortium_organization_headers) do
        {
          "HTTP_ACCEPT" => "application/vnd.api+json",
          "HTTP_AUTHORIZATION" =>
            "Basic " + consortium_organization_credentials,
        }
      end
      let(:params) do
        {
          "data" => {
            "type" => "providers",
            "attributes" => {
              "name" => "British Library",
              "globusUuid" => "9908a164-1e4f-4c17-ae1b-cc318839d6c8",
              "displayName" => "British Library",
              "website" => "https://www.bl.uk",
              "region" => "Americas",
              "systemEmail" => "Pepe@mdm.cod",
              "country" => "GB",
            },
          },
        }
      end

      xit "updates the record" do
        put "/providers/#{provider.symbol}",
            params, consortium_organization_headers

        expect(last_response.status).to eq(200)
        expect(json.dig("data", "attributes", "displayName")).to eq(
          "British Library",
        )
        expect(json.dig("data", "attributes", "globusUuid")).to eq(
          "9908a164-1e4f-4c17-ae1b-cc318839d6c8",
        )
      end
    end

    context "removes globus_uuid" do
      let(:params) do
        {
          "data" => {
            "type" => "providers", "attributes" => { "globusUuid" => nil }
          },
        }
      end

      it "updates the record" do
        put "/providers/#{provider.symbol}", params, headers

        expect(last_response.status).to eq(200)
        expect(json.dig("data", "attributes", "displayName")).to eq(
          "My provider",
        )
        expect(json.dig("data", "attributes", "globusUuid")).to be_nil
      end
    end

    context "invalid globus_uuid" do
      let(:params) do
        {
          "data" => {
            "type" => "providers", "attributes" => { "globusUuid" => "abc" }
          },
        }
      end

      it "updates the record" do
        put "/providers/#{provider.symbol}", params, headers

        expect(last_response.status).to eq(422)
        expect(json["errors"].first).to eq(
          "source" => "globus_uuid", "title" => "Abc is not a valid UUID", "uid" => provider.uid
        )
      end
    end

    context "ror_id in wrong format" do
      let(:params) do
        {
          "data" => {
            "type" => "providers",
            "attributes" => { "rorId" => "ror.org/05njkjr15" },
          },
        }
      end

      it "raises error" do
        put "/providers/#{provider.symbol}", params, headers

        expect(last_response.status).to eq(422)
        expect(json["errors"].first).to eq(
          "source" => "ror_id", "title" => "ROR ID should be a url", "uid" => provider.uid
        )
      end
    end

    context "using basic auth" do
      let(:params) do
        {
          "data" => {
            "type" => "providers",
            "attributes" => {
              "name" => "British Library",
              "displayName" => "British Library",
              "region" => "Americas",
              "systemEmail" => "Pepe@mdm.cod",
              "website" => "https://www.bl.uk",
              "country" => "GB",
            },
          },
        }
      end
      let(:admin) do
        create(
          :provider,
          symbol: "ADMIN", role_name: "ROLE_ADMIN", password_input: "12345",
        )
      end
      let(:credentials) do
        admin.encode_auth_param(username: "ADMIN", password: "12345")
      end
      let(:headers) do
        {
          "HTTP_ACCEPT" => "application/vnd.api+json",
          "HTTP_AUTHORIZATION" => "Basic " + credentials,
        }
      end

      xit "updates the record" do
        put "/providers/#{provider.symbol}", params, headers

        expect(last_response.status).to eq(200)
        expect(json.dig("data", "attributes", "systemEmail")).to eq(
          "Pepe@mdm.cod",
        )
      end
    end

    context "when the resource doesn't exist" do
      let(:params) do
        {
          "data" => {
            "type" => "providers",
            "attributes" => {
              "name" => "British Library",
              "displayName" => "British Library",
              "region" => "Americas",
              "website" => "https://www.bl.uk",
              "systemEmail" => "Pepe@mdm.cod",
              "country" => "GB",
            },
          },
        }
      end

      it "returns status code 404" do
        put "/providers/xxx", params, headers

        expect(last_response.status).to eq(404)
      end
    end
  end

  describe "DELETE /providers/:id" do
    let!(:provider) { create(:provider) }

    before do
      Provider.import
      sleep 2
    end

    it "deletes the provider" do
      delete "/providers/#{provider.symbol.downcase}",
             nil, admin_headers
      expect(last_response.status).to eq(204)
    end
  end
end
