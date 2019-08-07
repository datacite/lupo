require "rails_helper"
require 'pp'
 

describe "/events", type: :request, elasticsearch: true do
  before(:each) do
    allow(Time).to receive(:now).and_return(Time.mktime(2015, 4, 8))
    allow(Time.zone).to receive(:now).and_return(Time.mktime(2015, 4, 8))
  end

  let(:event) { build(:event) }
  let(:errors) { [{ "status" => "401", "title"=>"Bad credentials."}] }

  # Successful response from creating via the API.
  let(:success) { { "id" => event.uuid,
                    "type" => "events",
                    "attributes"=>{
                      "subjId" => "http://www.citeulike.org/user/dbogartoit",
                      "objId" => "http://doi.org/10.1371/journal.pmed.0030186",
                      "messageAction"=>"create",
                      "sourceToken"=>"citeulike_123",
                      "relationTypeId"=>"bookmarks",
                      "sourceId"=>"citeulike",
                      "total"=>1,
                      "license"=>"https://creativecommons.org/publicdomain/zero/1.0/",
                      "occurredAt"=>"2015-04-08T00:00:00.000Z",
                      "subj"=> {"@id"=>"http://www.citeulike.org/user/dbogartoit",
                                "@type"=>"CreativeWork",
                                "author"=>[{"givenName"=>"dbogartoit"}],
                                "name"=>"CiteULike bookmarks for user dbogartoit",
                                "publisher"=> { "@type" => "Organization", "name" => "CiteULike" },
                                "periodical"=> { "@type" => "Periodical",  "@id" => "https://doi.org/10.13039/100011326", "name" => "CiteULike", "issn" => "9812-847X" },
                                "funder"=> { "@type" => "Organization", "@id" => "https://doi.org/10.13039/100011326", "name" => "CiteULike" },
                                "version" => "1.0",
                                "proxyIdentifiers" => ["10.13039/100011326"],
                                "datePublished"=>"2006-06-13T16:14:19Z",
                                "dateModified"=>"2006-06-13T16:14:19Z",
                                "url"=>"http://www.citeulike.org/user/dbogartoit"
                      },
                      "obj"=>{}
                    }}}

  let(:token) { User.generate_token(role_id: "staff_admin") }
  let(:uuid) { SecureRandom.uuid }
  let(:headers) do
    { "HTTP_ACCEPT" => "application/vnd.api+json; version=2",
      "HTTP_AUTHORIZATION" => "Bearer #{token}" }
  end

  context "create" do
    let(:uri) { "/events" }
    let(:params) do
      { "data" => { "type" => "events",
                    "id" => event.uuid,
                    "attributes" => {
                      "subjId" => event.subj_id,
                      "subj" => event.subj,
                      "objId" => event.obj_id,
                      "relationTypeId" => event.relation_type_id,
                      "sourceId" => event.source_id,
                      "sourceToken" => event.source_token } } }
    end

    context "as admin user" do
      it "JSON" do
        post uri, params, headers

        expect(last_response.status).to eq(201)
        expect(json["errors"]).to be_nil
        expect(json.dig("data", "id")).to eq(event.uuid)
        # expect(json.dig("data", "relationships", "dois", "data")).to eq([{"id"=>"10.1371/journal.pmed.0030186", "type"=>"dois"}])
      end
    end

    context "with very long url" do
      let(:url) {"http://navigator.eumetsat.int/soapservices/cswstartup?service=csw&version=2.0.2&request=getrecordbyid&outputschema=http%3A%2F%2Fwww.isotc211.org%2F2005%2Fgmd&id=eo%3Aeum%3Adat%3Amult%3Arac-m11-iasia"}
      let(:params) do
        { "data" => { "type" => "events",
                      "attributes" => {
                        "subjId" => event.subj_id,
                        "subj" => event.subj,
                        "objId" => url,
                        "relationTypeId" => event.relation_type_id,
                        "sourceId" => "datacite-url",
                        "sourceToken" => event.source_token } } }
      end

      it "JSON" do
        post uri, params, headers

        expect(last_response.status).to eq(201)
        expect(json["errors"]).to be_nil
        expect(json.dig("data", "id")).not_to eq(event.uuid)
        expect(json.dig("data", "attributes", "objId")).to eq(url)
      end
    end

    context "as staff user" do
      let(:token) { User.generate_token(role_id: "staff_user") }

      it "JSON" do
        post uri, params, headers

        expect(last_response.status).to eq(403)
        expect(json["errors"]).to eq([{"status"=>"403", "title"=>"You are not authorized to access this resource."}])
        expect(json["data"]).to be_nil
      end
    end

    context "as regular user" do
      let(:token) { User.generate_token(role_id: "user") }

      it "JSON" do
        post uri, params, headers

        expect(last_response.status).to eq(403)
        expect(json["errors"]).to eq([{"status"=>"403", "title"=>"You are not authorized to access this resource."}])
        expect(json["data"]).to be_blank
      end
    end

    context "without sourceToken" do
      let(:params) do
        { "data" => { "type" => "events",
                      "attributes" => {
                        "uuid" => uuid,
                        "subjId" => event.subj_id,
                        "sourceId" => event.source_id } } }
      end

      it "JSON" do
        post uri, params, headers

        expect(last_response.status).to eq(422)
        expect(json["errors"]).to eq([{"status"=>422, "title"=>"Source token can't be blank"}])
        expect(json["data"]).to be_nil
      end
    end

    context "without sourceId" do
      let(:params) do
        { "data" => { "type" => "events",
                      "attributes" => {
                        "uuid" => uuid,
                        "subjId" => event.subj_id,
                        "sourceToken" => event.source_token } } }
      end

      it "JSON" do
        post uri, params, headers

        expect(last_response.status).to eq(422)
        expect(json["errors"]).to eq([{"status"=>422, "title"=>"Source can't be blank"}])
        expect(json["data"]).to be_blank
      end
    end

    context "without subjId" do
      let(:params) do
        { "data" => { "type" => "events",
                      "attributes" => {
                        "uuid" => uuid,
                        "sourceId" => event.source_id,
                        "sourceToken" => event.source_token } } }
      end

      it "JSON" do
        post uri, params, headers

        expect(last_response.status).to eq(422)
        expect(json["errors"]).to eq([{"status"=>422, "title"=>"Subj can't be blank"}])
        expect(json["data"]).to be_blank
      end
    end

    context "with wrong API token" do
      let(:headers) do
        { "HTTP_ACCEPT" => "application/vnd.api+json; version=2",
          "HTTP_AUTHORIZATION" => "Bearer 12345678" }
      end

      it "JSON" do
        post uri, params, headers
        expect(last_response.status).to eq(401)

        expect(json["errors"]).to eq(errors)
        expect(json["data"]).to be_blank
      end
    end

    context "with missing data param" do
      let(:params) do
        { "event" => { "type" => "events",
                         "attributes" => {
                           "uuid" => uuid,
                           "sourceToken" => "123" } } }
      end

      it "JSON" do
        post uri, params, headers

        expect(last_response.status).to eq(422)
        expect(json.dig("errors", 0, "title")).to start_with("Invalid payload")
        expect(json["data"]).to be_blank
      end
    end

    context "with params in wrong format" do
      let(:params) { { "data" => "10.1371/journal.pone.0036790 2012-05-15 New Dromaeosaurids (Dinosauria: Theropoda) from the Lower Cretaceous of Utah, and the Evolution of the Dromaeosaurid Tail" } }

      it "JSON" do
        post uri, params, headers

        expect(last_response.status).to eq(422)
        error = json["errors"].first
        expect(error["status"]).to eq("422")
        expect(error["title"]).to start_with("Invalid payload")
        expect(json["data"]).to be_blank
      end
    end

    context "existing entry" do
      let!(:event) { create(:event) }

      it "JSON" do
        post uri, params, headers

        expect(last_response.status).to eq(200)
        expect(json["errors"]).to be_nil
        expect(json.dig("data", "id")).to eq(event.uuid)
        # expect(json.dig("data", "relationships", "dois", "data")).to eq([{"id"=>"10.1371/journal.pmed.0030186", "type"=>"dois"}])
      end
    end

    context "with registrant information" do
      let(:uri) { "/events" }
      let(:params) do
        { "data" => { "type" => "events",
                      "attributes" => {
                        "subjId" => "https://doi.org/10.18713/jimis-170117-1-2",
                        "subj" => {"@id":"https://doi.org/10.18713/jimis-170117-1-2","@type":"ScholarlyArticle","datePublished":"2017","proxyIdentifiers":[],"registrantId":"datacite.inist.umr7300"},
                        "obj" => {"@id":"https://doi.org/10.1016/j.jastp.2013.05.001","@type":"ScholarlyArticle","datePublished":"2013-09","proxyIdentifiers":["13646826"],"registrantId":"datacite.crossref.citations"},
                        "objId" => "https://doi.org/10.1016/j.jastp.2013.05.001",
                        "relationTypeId" => "references",
                        "sourceId" => "datacite-crossref",
                        "sourceToken" => "sourceToken" } } }
      end

      it "has registrant aggregation" do
        post uri, params, headers
      

        expect(last_response.status).to eq(201)
        expect(json["errors"]).to be_nil
        expect(json.dig("data", "id")).not_to eq(event.uuid)
        expect(json.dig("data", "attributes", "objId")).to eq("https://doi.org/10.1016/j.jastp.2013.05.001")

        Event.import
        sleep 1
        get uri, nil, headers

        expect(json.dig("meta", "registrants",0,"count")).to eq(1)
        expect(json.dig("meta", "registrants",0,"id")).to eq("datacite.crossref.citations")
      end

      it "has citationsHistogram aggregation with correct citation year" do
        post uri, params, headers
      
        expect(last_response.status).to eq(201)
        expect(json["errors"]).to be_nil
   
        Event.import
        sleep 1
        get uri+"?aggregations=metrics_aggregations", nil, headers

        expect(json.dig("meta", "citationsHistogram","years",0,"title")).to eq("2017")
      end
    end
  end

  context "upsert" do
    let(:uri) { "/events/#{event.uuid}" }
    let(:params) do
      { "data" => { "type" => "events",
                    "id" => event.uuid,
                    "attributes" => {
                      "subjId" => event.subj_id,
                      "subj" => event.subj,
                      "objId" => event.obj_id,
                      "relationTypeId" => event.relation_type_id,
                      "sourceId" => event.source_id,
                      "sourceToken" => event.source_token } } }
    end

    context "as admin user" do
      it "JSON" do
        put uri, params, headers

        expect(last_response.status).to eq(201)
        expect(json["errors"]).to be_nil
        expect(json.dig("data", "id")).to eq(event.uuid)
        # expect(json.dig("data", "relationships", "dois", "data")).to eq([{"id"=>"10.1371/journal.pmed.0030186", "type"=>"dois"}])
      end
    end

    context "as staff user" do
      let(:token) { User.generate_token(role_id: "staff_user") }

      it "JSON" do
        put uri, params, headers

        expect(last_response.status).to eq(403)
        expect(json["errors"]).to eq([{"status"=>"403", "title"=>"You are not authorized to access this resource."}])
        expect(json["data"]).to be_nil
      end
    end

    context "as regular user" do
      let(:token) { User.generate_token(role_id: "user") }

      it "JSON" do
        put uri, params, headers

        expect(last_response.status).to eq(403)
        expect(json["errors"]).to eq([{"status"=>"403", "title"=>"You are not authorized to access this resource."}])
        expect(json["data"]).to be_blank
      end
    end

    context "without sourceToken" do
      let(:params) do
        { "data" => { "type" => "events",
                      "id" => uuid,
                      "attributes" => {
                        "subjId" => event.subj_id,
                        "sourceId" => event.source_id } } }
      end

      it "JSON" do
        put uri, params, headers

        expect(last_response.status).to eq(422)
        expect(json["errors"]).to eq([{"status"=>422, "title"=>"Source token can't be blank"}])
        expect(json["data"]).to be_nil
      end
    end

    context "without sourceId" do
      let(:params) do
        { "data" => { "type" => "events",
                      "id" => uuid,
                      "attributes" => {
                        "subjId" => event.subj_id,
                        "sourceToken" => event.source_token } } }
      end

      it "JSON" do
        put uri, params, headers

        expect(last_response.status).to eq(422)
        expect(json["errors"]).to eq([{"status"=>422, "title"=>"Source can't be blank"}])
        expect(json["data"]).to be_blank
      end
    end

    context "without subjId" do
      let(:params) do
        { "data" => { "type" => "events",
                      "id" => uuid,
                      "attributes" => {
                        "sourceId" => event.source_id,
                        "sourceToken" => event.source_token } } }
      end

      it "JSON" do
        put uri, params, headers

        expect(last_response.status).to eq(422)
        expect(json["errors"]).to eq([{"status"=>422, "title"=>"Subj can't be blank"}])
        expect(json["data"]).to be_blank
      end
    end

    context "with wrong API token" do
      let(:headers) do
        { "HTTP_ACCEPT" => "application/vnd.api+json; version=2",
          "HTTP_AUTHORIZATION" => "Bearer 12345678" }
      end

      it "JSON" do
        put uri, params, headers

        expect(last_response.status).to eq(401)
        expect(json["errors"]).to eq(errors)
        expect(json["data"]).to be_blank
      end
    end

    context "with missing data param" do
      let(:params) do
        { "event" => { "type" => "events",
                       "id" => uuid,
                       "attributes" => {
                         "sourceToken" => "123" } } }
      end

      it "JSON" do
        put uri, params, headers

        expect(last_response.status).to eq(422)
        expect(json.dig("errors", 0, "title")).to start_with("Invalid payload")
        expect(json["data"]).to be_blank
      end
    end

    context "with params in wrong format" do
      let(:params) { { "data" => "10.1371/journal.pone.0036790 2012-05-15 New Dromaeosaurids (Dinosauria: Theropoda) from the Lower Cretaceous of Utah, and the Evolution of the Dromaeosaurid Tail" } }

      it "JSON" do
        put uri, params, headers

        expect(last_response.status).to eq(422)
        error = json["errors"].first
        expect(error["status"]).to eq("422")
        expect(error["title"]).to start_with("Invalid payload")
        expect(json["data"]).to be_blank
      end
    end

    context "entry already exists" do
      let!(:event) { create(:event) }

      it "JSON" do
        put uri, params, headers

        expect(last_response.status).to eq(200)
        expect(json["errors"]).to be_nil
        # expect(json.dig("data", "relationships", "dois", "data")).to eq([{"id"=>"10.1371/journal.pmed.0030186", "type"=>"dois"}])
      end
    end
  end

  context "update" do
    let(:event) { create(:event) }
    # let!(:doi) { create(:doi, doi: "10.1371/journal.pmed.0030186", aasm_state: "findable") }
    let(:uri) { "/events/#{event.uuid}?include=dois" }

    let(:params) do
      { "data" => { "type" => "events",
                    "id" => event.uuid,
                    "attributes" => {
                      "subjId" => event.subj_id,
                      "subj" => event.subj,
                      "objId" => event.obj_id,
                      "relationTypeId" => event.relation_type_id,
                      "sourceId" => event.source_id,
                      "sourceToken" => event.source_token } } }
    end

    context "as admin user" do
      it "JSON" do
        put uri, params, headers

        expect(last_response.status).to eq(200)
        expect(json["errors"]).to be_nil
        # expect(json.dig("data", "relationships", "dois", "data")).to eq([{"id"=>"10.1371/journal.pmed.0030186", "type"=>"dois"}])
      end
    end

    context "as staff user" do
      let(:token) { User.generate_token(role_id: "staff_user") }

      it "JSON" do
        put uri, params, headers

        expect(last_response.status).to eq(403)
        expect(json["errors"]).to eq([{"status"=>"403", "title"=>"You are not authorized to access this resource."}])
        expect(json["data"]).to be_nil
      end
    end

    context "as regular user" do
      let(:token) { User.generate_token(role_id: "user") }

      it "JSON" do
        put uri, params, headers

        expect(last_response.status).to eq(403)
        expect(json["errors"]).to eq([{"status"=>"403", "title"=>"You are not authorized to access this resource."}])
        expect(json["data"]).to be_blank
      end
    end

    context "with wrong API token" do
      let(:headers) do
        { "HTTP_ACCEPT" => "application/vnd.api+json; version=2",
          "HTTP_AUTHORIZATION" => "Bearer 12345678" }
      end

      it "JSON" do
        put uri, params, headers

        expect(last_response.status).to eq(401)
        expect(json["errors"]).to eq(errors)
        expect(json["data"]).to be_blank
      end
    end

    context "with missing data param" do
      let(:params) do
        { "event" => { "type" => "events",
                       "id" => uuid,
                       "attributes" => {
                         "sourceToken" => "123" } } }
      end

      it "JSON" do
        put uri, params, headers
        
        expect(last_response.status).to eq(422)
        expect(json.dig("errors", 0, "title")).to start_with("Invalid payload")
        expect(json["data"]).to be_blank
      end
    end

    context "with params in wrong format" do
      let(:params) { { "data" => "10.1371/journal.pone.0036790 2012-05-15 New Dromaeosaurids (Dinosauria: Theropoda) from the Lower Cretaceous of Utah, and the Evolution of the Dromaeosaurid Tail" } }

      it "JSON" do
        put uri, params, headers

        expect(last_response.status).to eq(422)
        error = json["errors"].first
        expect(error["status"]).to eq("422")
        expect(error["title"]).to start_with("Invalid payload")
        expect(json["data"]).to be_blank
      end
    end
  end

  context "show" do
    let!(:event) { create(:event) }
    let(:uri) { "/events/#{event.uuid}" }

    # context "as admin user" do
    #   it "JSON" do
    #     sleep 1
    #     get uri, nil, headers
    #     expect(last_response.body).to eq(200)

    #     response = JSON.parse(last_response.body)
    #     attributes = response.dig("data", "attributes")
    #     expect(response.dig("data", "relationships", "subj", "data")).to eq("id"=>event.subj_id, "type"=>"objects")
    #   end
    # end

    # context "as staff user" do
    #   let(:token) { User.generate_token(role_id: "staff_user") }

    #   it "JSON" do
    #     get uri, nil, headers
    #     expect(last_response.status).to eq(200)

    #     response = JSON.parse(last_response.body)
    #     expect(response.dig("data", "relationships", "subj", "data")).to eq("id"=>event.subj_id, "type"=>"objects")
    #   end
    # end

    # context "as regular user" do
    #   let(:token) { User.generate_token(role_id: "user") }

    #   it "JSON" do
    #     get uri, nil, headers
    #     expect(last_response.status).to eq(200)

    #     response = JSON.parse(last_response.body)
    #     expect(response.dig("data", "relationships", "subj", "data")).to eq("id"=>event.subj_id, "type"=>"objects")
    #   end
    # end

    context "event not found" do
      let(:uri) { "/events/#{event.uuid}x" }

      it "JSON" do
        get uri, nil, headers

        expect(last_response.status).to eq(404)
        expect(json["errors"]).to eq([{"status"=>"404", "title"=>"The resource you are looking for doesn't exist."}])
        expect(json["data"]).to be_nil
      end
    end
  end

  context "index" do
  #   # let!(:event) { create(:event) }
  #   # let(:uri) { "/events" }
    
  # TODO: need further setup
    context "check meta unique" do
      let!(:event) { create_list(:event_for_datacite_related, 5) }
      let(:uri) { "/events?aggregations=metrics_aggregations" }
      
      before do
        Event.import
        sleep 1
      end

      # Exclude the token header.
      let(:headers) do
        { "HTTP_ACCEPT" => "application/vnd.api+json; version=2" }
      end

      it "json" do
        get uri, nil, headers

        expect(last_response.status).to eq(200)
        response = JSON.parse(last_response.body)
        citations = response.dig("meta", "uniqueCitations")
        total = response.dig("meta", "total")
    
        expect(total).to eq(5)
        expect(citations.first["citations"]).to eq(5)
        expect(citations.first["id"]).to eq("10.5061/dryad.47sd5/1")
      end
    end

    context "check meta duplicated" do
      let!(:event) { create(:event_for_datacite_related,  subj_id:"http://doi.org/10.0260/co.2004960.v1") }
      let!(:copies) { create(:event_for_datacite_related,  subj_id:"http://doi.org/10.0260/co.2004960.v1", relation_type_id: "cites") }
      let(:uri) { "/events?aggregations=metrics_aggregations" }

      before do
        Event.import
        sleep 1
      end

      # Exclude the token header.
      let(:headers) do
        { "HTTP_ACCEPT" => "application/vnd.api+json; version=2" }
      end

      it "json" do
        get uri, nil, headers

        expect(last_response.status).to eq(200)
        response = JSON.parse(last_response.body)
        citations = response.dig("meta", "uniqueCitations")
        total = response.dig("meta", "total")

        expect(total).to eq(2)
        expect(citations.first["citations"]).to eq(1)
        expect(citations.first["id"]).to eq("10.0260/co.2004960.v1")
      end
    end

    context "unique citations for a list of dois" do
      let!(:event) { create_list(:event_for_datacite_related, 50) }
      let!(:copies) { create(:event_for_datacite_related,  subj_id:"http://doi.org/10.0260/co.2004960.v1", relation_type_id: "cites") }
      let(:dois) {"10.5061/dryad.47sd5e/2,10.5061/dryad.47sd5e/3,10.5061/dryad.47sd5e/4,10.0260/co.2004960.v1"}
      let(:uri) { "/events?aggregations=metrics_aggregations&dois=#{dois}" }

      before do
        Event.import
        sleep 1
      end

      # Exclude the token header.
      let(:headers) do
        { "HTTP_ACCEPT" => "application/vnd.api+json; version=2" }
      end

      it "json" do
        get uri, nil, headers

        expect(last_response.status).to eq(200)
        response = JSON.parse(last_response.body)
        citations = response.dig("meta", "uniqueCitations")
        total = response.dig("meta", "total")

        expect(total).to eq(51)
        # TODO
        # expect((citations.select { |doi| dois.split(",").include?(doi["id"]) }).length).to eq(4)
      end
    end

    # Just test that the API can be accessed without a token.
    # context "with no API key" do

    #   # Exclude the token header.
    #   let(:headers) do
    #     { "HTTP_ACCEPT" => "application/json" }
    #   end

    #   it "JSON" do
    #     sleep 1
    #     get uri, nil, headers
    #     puts last_response.body

    #     response = JSON.parse(last_response.body)
    #     attributes = response.dig("data", 0, "attributes")
    #     expect(attributes["subj-id"]).to eq(event.subj_id)
    #   end

    #   it "No accept header" do
    #     sleep 1
    #     get uri

    #     response = JSON.parse(last_response.body)
    #     attributes = response.dig("data", 0, "attributes")
    #     expect(attributes["subj-id"]).to eq(event.subj_id)
    #   end
    # end

    # context "query by obj-id" do
    #   let(:uri) { "/events?obj-id=#{event.obj_id}" }

    #   # Exclude the token header.
    #   let(:headers) do
    #     { "HTTP_ACCEPT" => "application/json" }
    #   end

    #   it "json" do
    #     get uri, nil, headers

    #     expect(last_response.status).to eq(200)

    #     response = JSON.parse(last_response.body)
    #     attributes = response.dig("data", 0, "attributes")
    #     expect(attributes["obj-id"]).to eq(event.obj_id)
    #   end
    # end

    # context "query by subj-id" do
    #   let(:uri) { "/events?subj-id=#{event.subj_id}" }

    #   # Exclude the token header.
    #   let(:headers) do
    #     { "HTTP_ACCEPT" => "application/json" }
    #   end

    #   it "json" do
    #     get uri, nil, headers

    #     expect(last_response.status).to eq(200)

    #     response = JSON.parse(last_response.body)
    #     attributes = response.dig("data", 0, "attributes")
    #     expect(attributes["subj-id"]).to eq(event.subj_id)
    #   end
    # end

    # context "query by unknown subj-id" do
    #   let(:uri) { "/events?subj-id=xxx" }

    #   # Exclude the token header.
    #   let(:headers) do
    #     { "HTTP_ACCEPT" => "application/json" }
    #   end

    #   it "json" do
    #     get uri, nil, headers

    #     expect(last_response.status).to eq(200)

    #     response = JSON.parse(last_response.body)

    #     expect(response["errors"]).to be_nil
    #     expect(response["data"]).to be_empty
    #   end
    # end

    # context "query by obj-id as doi" do
    #   let(:doi) { "10.1371/journal.pmed.0030186" }
    #   let(:event) { create(:event, obj_id: doi) }
    #   let(:uri) { "/events?obj-id=#{doi}" }

    #   # Exclude the token header.
    #   let(:headers) do
    #     { "HTTP_ACCEPT" => "application/json" }
    #   end

    #   it "json" do
    #     get uri, nil, headers

    #     expect(last_response.status).to eq(200)

    #     response = JSON.parse(last_response.body)
    #     attributes = response.dig("data", 0, "attributes")
    #     expect(attributes["obj-id"]).to eq(event.obj_id)
    #   end
    # end

    # context "query by doi as doi" do
    #   let(:doi) { "10.1371/journal.pmed.0030186" }
    #   let(:event) { create(:event, obj_id: doi) }
    #   let(:uri) { "/events?doi=#{doi}" }

    #   # Exclude the token header.
    #   let(:headers) do
    #     { "HTTP_ACCEPT" => "application/json" }
    #   end

    #   it "json" do
    #     get uri, nil, headers

    #     expect(last_response.status).to eq(200)

    #     response = JSON.parse(last_response.body)
    #     attributes = response.dig("data", 0, "attributes")
    #     expect(attributes["obj-id"]).to eq(event.obj_id)
    #   end
    # end

    # context "query by unknown obj-id" do
    #   let(:uri) { "/events?obj-id=xxx" }

    #   # Exclude the token header.
    #   let(:headers) do
    #     { "HTTP_ACCEPT" => "application/json" }
    #   end

    #   it "json" do
    #     get uri, nil, headers

    #     expect(last_response.status).to eq(200)

    #     response = JSON.parse(last_response.body)

    #     expect(response["errors"]).to be_nil
    #     expect(response["data"]).to be_empty
    #   end
    # end

    # context "query by source-id" do
    #   let(:uri) { "/events?source-id=citeulike" }

    #   # Exclude the token header.
    #   let(:headers) do
    #     { "HTTP_ACCEPT" => "application/json" }
    #   end

    #   it "json" do
    #     get uri, nil, headers

    #     expect(last_response.status).to eq(200)

    #     response = JSON.parse(last_response.body)
    #     attributes = response.dig("data", 0, "attributes")
    #     expect(attributes["subj-id"]).to eq(event.subj_id)
    #   end
    # end
  end

  context "destroy" do
    let(:event) { create(:event) }
    let(:uri) { "/events/#{event.uuid}" }

    # context "as admin user" do
    #   it "JSON" do
    #     delete uri, nil, headers
    #     expect(last_response.status).to eq(200)

    #     response = JSON.parse(last_response.body)
    #     expect(response["errors"]).to be_nil
    #     expect(response["data"]).to eq({})
    #   end
    # end

    # context "as staff user" do
    #   let(:token) { User.generate_token(role_id: "staff_user") }

    #   it "JSON" do
    #     delete uri, nil, headers
    #     expect(last_response.status).to eq(401)

    #     response = JSON.parse(last_response.body)
    #     expect(response["errors"]).to eq(errors)
    #     expect(response["data"]).to be_nil
    #   end
    # end

    # context "as regular user" do
    #   let(:token) { User.generate_token(role_id: "user") }

    #   it "JSON" do
    #     delete uri, nil, headers
    #     expect(last_response.status).to eq(401)

    #     response = JSON.parse(last_response.body)
    #     expect(response["errors"]).to eq(errors)
    #     expect(response["data"]).to be_nil
    #   end
    # end

    # context "with wrong API key" do
    #   let(:headers) do
    #     { "HTTP_ACCEPT" => "application/json",
    #       "HTTP_AUTHORIZATION" => "Token token=12345678" }
    #   end

    #   it "JSON" do
    #     delete uri, nil, headers
    #     expect(last_response.status).to eq(401)

    #     response = JSON.parse(last_response.body)
    #     expect(response["errors"]).to eq(errors)
    #     expect(response["data"]).to be_nil
    #   end
    # end

    context "event not found" do
      let(:uri) { "/events/#{event.uuid}x" }

      it "JSON" do
        delete uri, nil, headers

        expect(last_response.status).to eq(404)
        expect(json["errors"]).to eq([{"status"=>"404", "title"=>"The resource you are looking for doesn't exist."}])
        expect(json["data"]).to be_nil
      end
    end
  end
end
