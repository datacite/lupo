require 'rails_helper'

describe "dois", type: :request do
  let(:admin) { create(:provider, symbol: "ADMIN") }
  let(:admin_bearer) { Client.generate_token(role_id: "staff_admin", uid: admin.symbol, password: admin.password) }
  let(:admin_headers) { {'ACCEPT'=>'application/vnd.api+json', 'CONTENT_TYPE'=>'application/vnd.api+json', 'Authorization' => 'Bearer ' + admin_bearer}}

  let(:provider) { create(:provider, symbol: "DATACITE") }
  let(:client) { create(:client, provider: provider, symbol: ENV['MDS_USERNAME'], password: ENV['MDS_PASSWORD']) }
  let!(:prefix) { create(:prefix, prefix: "10.14454") }
  let!(:client_prefix) { create(:client_prefix, client: client, prefix: prefix) }
  let!(:dois) { create_list(:doi, 3, client: client) }
  let(:doi) { create(:doi, client: client) }
  let(:bearer) { Client.generate_token(role_id: "client_admin", uid: client.symbol, provider_id: provider.symbol.downcase, client_id: client.symbol.downcase, password: client.password) }
  let(:headers) { { 'ACCEPT'=>'application/vnd.api+json', 'CONTENT_TYPE'=>'application/vnd.api+json', 'Authorization' => 'Bearer ' + bearer }}

  describe 'GET /dois', elasticsearch: true do
    before do
      sleep 1
      get '/dois', headers: headers
    end

    # it 'returns dois' do
    #   expect(json['data'].size).to eq(0)
    # end

    it 'returns status code 200' do
      expect(response).to have_http_status(200)
    end
  end

  describe 'GET /dois/:id' do
    context 'when the record exists' do
      before { get "/dois/#{doi.doi}", headers: headers }

      it 'returns the Doi' do
        expect(json).not_to be_empty
        expect(json.dig('data', 'attributes', 'doi')).to eq(doi.doi.downcase)
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end
    end

    context 'when the record does not exist' do
      before { get "/dois/10.5256/xxxx", headers: headers }

      it 'returns status code 404' do
        expect(response).to have_http_status(404)
      end

      it 'returns a not found message' do
        expect(json).to eq("errors"=>[{"status"=>"404", "title"=>"The resource you are looking for doesn't exist."}])
      end
    end

    context 'anonymous user' do
      before { get "/dois/#{doi.doi}" }

      it 'returns the Doi' do
        expect(json).not_to be_empty
        expect(json.fetch('errors')).to eq([{"status"=>"401", "title"=>"Bad credentials."}])
      end

      it 'returns status code 401' do
        expect(response).to have_http_status(401)
      end
    end

    context 'invalid password' do
      let(:bearer) { Client.generate_token(role_id: "client_admin", uid: client.symbol, provider_id: provider.symbol.downcase, client_id: client.symbol.downcase, password: "abc") }
      let(:headers) { { 'ACCEPT'=>'application/vnd.api+json', 'CONTENT_TYPE'=>'application/vnd.api+json', 'Authorization' => 'Bearer ' + bearer }}

      before { get "/dois/#{doi.doi}" }

      it 'returns the Doi' do
        expect(json).not_to be_empty
        expect(json.fetch('errors')).to eq([{"status"=>"401", "title"=>"Bad credentials."}])
      end

      it 'returns status code 401' do
        expect(response).to have_http_status(401)
      end
    end
  end

  describe 'state' do
    let(:doi_id) { "10.14454/4K3M-NYVG" }
    let(:xml) { Base64.strict_encode64(file_fixture('datacite.xml').read) }
    let(:bearer) { User.generate_token(role_id: "client_admin", client_id: client.symbol.downcase) }
    let(:headers) { {'ACCEPT'=>'application/vnd.api+json', 'CONTENT_TYPE'=>'application/vnd.api+json', 'Authorization' => 'Bearer ' + bearer}}

    context 'initial state draft' do
      before { get "/dois/#{doi.doi}", headers: headers }

      it 'fetches the record' do
        expect(json.dig('data', 'attributes', 'url')).to eq(doi.url)
        expect(json.dig('data', 'attributes', 'doi')).to eq(doi.doi.downcase)
        expect(json.dig('data', 'attributes', 'titles')).to eq(doi.titles)
        expect(json.dig('data', 'attributes', 'isActive')).to be false
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end

      it 'initial state' do
        expect(json.dig('data', 'attributes', 'state')).to eq("draft")
      end
    end

    context 'register' do
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "xml" => xml,
              "url" => "http://www.bl.uk/pdf/pat.pdf",
              "event" => "register"
            }
          }
        }
      end
      before { patch "/dois/#{doi_id}", params: valid_attributes.to_json, headers: headers }

      it 'creates the record' do
        expect(json.dig('data', 'attributes', 'doi')).to eq(doi_id.downcase)
        expect(json.dig('data', 'attributes', 'url')).to eq("http://www.bl.uk/pdf/pat.pdf")
        expect(json.dig('data', 'attributes', 'isActive')).to be false
      end

      it 'returns status code 201' do
        expect(response).to have_http_status(201)
      end

      it 'sets state to registered' do
        expect(json.dig('data', 'attributes', 'state')).to eq("registered")
      end
    end

    context 'register no url' do
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "xml" => xml,
              "event" => "register"
            }
          }
        }
      end
      before { patch "/dois/#{doi_id}", params: valid_attributes.to_json, headers: headers }

      it 'creates the record' do
        expect(json.dig('data', 'attributes', 'doi')).to eq(doi_id.downcase)
        expect(json.dig('data', 'attributes', 'url')).to be_nil
        expect(json.dig('data', 'attributes', 'isActive')).to be false
      end

      it 'returns status code 201' do
        expect(response).to have_http_status(201)
      end

      it 'state remains draft' do
        expect(json.dig('data', 'attributes', 'state')).to eq("draft")
      end
    end

    context 'publish' do
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "url" => "http://www.bl.uk/pdf/pat.pdf",
              "xml" => xml,
              "event" => "publish"
            }
          }
        }
      end
      before { patch "/dois/#{doi_id}", params: valid_attributes.to_json, headers: headers }

      it 'updates the record' do
        expect(json.dig('data', 'attributes', 'doi')).to eq(doi_id.downcase)
        expect(json.dig('data', 'attributes', 'url')).to eq("http://www.bl.uk/pdf/pat.pdf")
        expect(json.dig('data', 'attributes', 'isActive')).to be true
      end

      it 'returns status code 201' do
        expect(response).to have_http_status(201)
      end

      it 'sets state to findable' do
        expect(json.dig('data', 'attributes', 'state')).to eq("findable")
      end
    end

    context 'publish no url' do
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "xml" => xml,
              "event" => "publish"
            }
          }
        }
      end
      before { patch "/dois/#{doi_id}", params: valid_attributes.to_json, headers: headers }

      it 'updates the record' do
        expect(json.dig('data', 'attributes', 'doi')).to eq(doi_id.downcase)
        expect(json.dig('data', 'attributes', 'url')).to be_nil
        expect(json.dig('data', 'attributes', 'isActive')).to be false
      end

      it 'returns status code 201' do
        expect(response).to have_http_status(201)
      end

      it 'state remains draft' do
        expect(json.dig('data', 'attributes', 'state')).to eq("draft")
      end
    end

    context 'hide' do
      let(:doi) { create(:doi, client: client, aasm_state: "findable") }
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "event" => "hide"
            }
          }
        }
      end
      before { patch "/dois/#{doi.doi}", params: valid_attributes.to_json, headers: headers }

      it 'updates the record' do
        expect(json.dig('data', 'attributes', 'doi')).to eq(doi.doi.downcase)
        expect(json.dig('data', 'attributes', 'isActive')).to be false
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end

      it 'state changes to register' do
        expect(json.dig('data', 'attributes', 'state')).to eq("registered")
      end
    end

    context 'hide with reason' do
      let(:doi) { create(:doi, client: client, aasm_state: "findable") }
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "event" => "hide",
              "reason" => "withdrawn by author"
            }
          }
        }
      end
      before { patch "/dois/#{doi.doi}", params: valid_attributes.to_json, headers: headers }

      it 'updates the record' do
        expect(json.dig('data', 'attributes', 'doi')).to eq(doi.doi.downcase)
        expect(json.dig('data', 'attributes', 'isActive')).to be false
        expect(json.dig('data', 'attributes', 'reason')).to eq("withdrawn by author")
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end

      it 'state changes to register' do
        expect(json.dig('data', 'attributes', 'state')).to eq("registered")
      end
    end
  end

  describe 'PATCH /dois/:id' do
    context 'when the record exists' do
      let(:xml) { Base64.strict_encode64(file_fixture('datacite.xml').read) }
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "url" => "http://www.bl.uk/pdf/pat.pdf",
              "xml" => xml
            }
          }
        }
      end
      before { patch "/dois/#{doi.doi}", params: valid_attributes.to_json, headers: headers }

      it 'updates the record' do
        expect(json.dig('data', 'attributes', 'url')).to eq("http://www.bl.uk/pdf/pat.pdf")
        expect(json.dig('data', 'attributes', 'doi')).to eq(doi.doi.downcase)
        expect(json.dig('data', 'attributes', 'titles')).to eq([{"title"=>"Eating your own Dog Food"}])
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end

      it 'sets state to draft' do
        expect(json.dig('data', 'attributes', 'state')).to eq("draft")
      end
    end

    context 'when the record exists no data attribute' do
      let(:xml) { Base64.strict_encode64(file_fixture('datacite.xml').read) }
      let(:valid_attributes) do
        {
          "url" => "http://www.bl.uk/pdf/pat.pdf",
          "xml" => xml
        }
      end
      before { patch "/dois/#{doi.doi}", params: valid_attributes.to_json, headers: headers }

      it 'raises an error' do
        expect(json.dig('errors')).to eq([{"status"=>"400", "title"=>"You need to provide a payload following the JSONAPI spec"}])
      end

      it 'returns status code 400' do
        expect(response).to have_http_status(400)
      end
    end

    context 'no creators validate' do
      let(:doi) { create(:doi, client: client, creators: nil) }
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "url" => "http://www.bl.uk/pdf/pat.pdf",
              "xml" => Base64.strict_encode64(doi.xml),
              "event" => "publish"
            }
          }
        }
      end
      before { put "/dois/#{doi.doi}", params: valid_attributes.to_json, headers: headers }

      it 'returns error' do
        expect(json["errors"]).to eq([{"source"=>"creators", "title"=>"Missing child element(s). expected is ( {http://datacite.org/schema/kernel-4}creator ). at line 4, column 0"}])
      end

      it 'returns status code 422' do
        expect(response).to have_http_status(422)
      end
    end

    context 'when the record exists https://github.com/datacite/lupo/issues/89' do
      let(:doi) { create(:doi, doi: "10.14454/119496", client: client) }
      let(:valid_attributes) { file_fixture('datacite_89.json').read }

      before { put "/dois/#{doi.doi}", params: valid_attributes, headers: headers }

      it 'returns no errors' do
        expect(json.dig('data', 'attributes', 'doi')).to eq(doi.doi)
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end
    end

    context 'schema 2.2' do
      let(:xml) { Base64.strict_encode64(file_fixture('datacite_schema_2.2.xml').read) }
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "xml" => xml,
              "url" => "http://www.bl.uk/pdf/patspec.pdf",
              "event" => "publish"
            }
          }
        }
      end
      before { patch "/dois/10.14454/10703", params: valid_attributes.to_json, headers: headers }

      it 'updates the record' do
        expect(json.dig('data', 'attributes', 'doi')).to eq("10.14454/10703")
        expect(json.dig('data', 'attributes', 'url')).to eq("http://www.bl.uk/pdf/patspec.pdf")
        expect(json.dig('data', 'attributes', 'titles')).to eq([{"title"=>"Właściwości rzutowań podprzestrzeniowych"}, {"title"=>"Translation of Polish titles", "titleType"=>"TranslatedTitle"}])
        expect(json.dig('data', 'attributes', 'schemaVersion')).to eq("http://datacite.org/schema/kernel-2.2")

        xml = Maremma.from_xml(Base64.decode64(json.dig('data', 'attributes', 'xml'))).fetch("resource", {})
        expect(xml.dig("titles", "title")).to eq(["Właściwości rzutowań podprzestrzeniowych", {"__content__"=>"Translation of Polish titles", "titleType"=>"TranslatedTitle"}])
      end

      it 'returns status code 201' do
        expect(response).to have_http_status(201)
      end
    end

    context 'NoMethodError https://github.com/datacite/lupo/issues/84' do
      let(:doi) { create(:doi, client: client) }
      let(:url) { "https://figshare.com/articles/Additional_file_1_of_Contemporary_ancestor_Adaptive_divergence_from_standing_genetic_variation_in_Pacific_marine_threespine_stickleback/6839054/1" }
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "url"=> url,
              "xml" => Base64.strict_encode64(doi.xml),
              "event" => "publish"
            }
          }
        }
      end

      before { put "/dois/#{doi.doi}", params: valid_attributes.to_json, headers: headers }

      it 'returns no errors' do
        expect(json.dig('data', 'attributes', 'doi')).to eq(doi.doi.downcase)
        expect(json.dig('data', 'attributes', 'url')).to eq(url)
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end
    end

    context 'when the record doesn\'t exist' do
      let(:doi_id) { "10.14454/4K3M-NYVG" }
      let(:xml) { Base64.strict_encode64(file_fixture('datacite.xml').read) }
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "url" => "http://www.bl.uk/pdf/pat.pdf",
              "xml" => xml,
              "event" => "publish"
            }
          }
        }
      end
      before { put "/dois/#{doi_id}", params: valid_attributes.to_json, headers: headers }

      it 'creates the record' do
        expect(json.dig('data', 'attributes', 'url')).to eq("http://www.bl.uk/pdf/pat.pdf")
        expect(json.dig('data', 'attributes', 'doi')).to eq(doi_id.downcase)
        expect(json.dig('data', 'attributes', 'titles')).to eq([{"title"=>"Eating your own Dog Food"}])
      end

      it 'returns status code 201' do
        expect(response).to have_http_status(201)
      end

      it 'sets state to findable' do
        expect(json.dig('data', 'attributes', 'state')).to eq("findable")
      end
    end

    context 'when the record doesn\'t exist no creators publish' do
      let(:doi_id) { "10.14454/077d-fj48" }
      let(:xml) { Base64.strict_encode64(file_fixture('datacite_missing_creator.xml').read) }
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "url" => "http://www.bl.uk/pdf/pat.pdf",
              "xml" => xml,
              "event" => "publish"
            }
          }
        }
      end
      before { put "/dois/#{doi_id}", params: valid_attributes.to_json, headers: headers }

      it 'returns error' do
        expect(json["errors"]).to eq([{"source"=>"creators", "title"=>"Missing child element(s). expected is ( {http://datacite.org/schema/kernel-4}creator ). at line 4, column 0"}])
      end

      it 'returns status code 422' do
        expect(response).to have_http_status(422)
      end
    end

    context 'when the record exists with conversion' do
      let(:xml) { Base64.strict_encode64(file_fixture('crossref.bib').read) }
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "url" => "http://www.bl.uk/pdf/pat.pdf",
              "xml" => xml
            }
          }
        }
      end
      before { patch "/dois/#{doi.doi}", params: valid_attributes.to_json, headers: headers }

      it 'updates the record' do
        expect(json.dig('data', 'attributes', 'url')).to eq("http://www.bl.uk/pdf/pat.pdf")
        expect(json.dig('data', 'attributes', 'doi')).to eq(doi.doi.downcase)
        expect(json.dig('data', 'attributes', 'titles')).to eq([{"title"=>"Automated quantitative histology reveals vascular morphodynamics during Arabidopsis hypocotyl secondary growth"}])
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end

      it 'sets state to registered' do
        expect(json.dig('data', 'attributes', 'state')).to eq("draft")
      end
    end

    context 'when the title is changed' do
      let(:xml) { Base64.strict_encode64(file_fixture('datacite.xml').read) }
      let(:titles) { [{ "title" => "Submitted chemical data for InChIKey=YAPQBXQYLJRXSA-UHFFFAOYSA-N" }] }
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "url" => "http://www.bl.uk/pdf/pat.pdf",
              "xml" => xml,
              "titles" => titles,
              "event" => "publish"
            }
          }
        }
      end
      before { patch "/dois/#{doi.doi}", params: valid_attributes.to_json, headers: headers }

      it 'updates the record' do
        expect(json.dig('data', 'attributes', 'url')).to eq("http://www.bl.uk/pdf/pat.pdf")
        expect(json.dig('data', 'attributes', 'doi')).to eq(doi.doi.downcase)
        expect(json.dig('data', 'attributes', 'titles')).to eq(titles)
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end

      it 'sets state to findable' do
        expect(json.dig('data', 'attributes', 'state')).to eq("findable")
      end
    end

    context 'when the creators change' do
      let(:xml) { Base64.strict_encode64(file_fixture('datacite.xml').read) }
      let(:creators) { [{ "name"=>"Ollomi, Benjamin" }, { "name"=>"Duran, Patrick" }] }
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "url" => "http://www.bl.uk/pdf/pat.pdf",
              "xml" => xml,
              "creators" => creators,
              "event" => "publish"
            }
          }
        }
      end
      before { patch "/dois/#{doi.doi}", params: valid_attributes.to_json, headers: headers }

      it 'updates the record' do
        expect(json.dig('data', 'attributes', 'url')).to eq("http://www.bl.uk/pdf/pat.pdf")
        expect(json.dig('data', 'attributes', 'doi')).to eq(doi.doi.downcase)
        expect(json.dig('data', 'attributes', 'creators')).to eq(creators)
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end

      it 'sets state to findable' do
        expect(json.dig('data', 'attributes', 'state')).to eq("findable")
      end
    end

    context 'fail when we transfer a DOI as provider' do

      let(:provider_bearer) { User.generate_token(uid: "datacite", role_id: "provider_admin", name: "DataCite", email:"support@datacite.org", provider_id: "datacite") }
      let(:provider_headers) { {'ACCEPT'=>'application/vnd.api+json', 'CONTENT_TYPE'=>'application/vnd.api+json', 'Authorization' => 'Bearer ' + provider_bearer}}

      let(:doi) { create(:doi, client: client) }
      let(:new_client) { create(:client, symbol: "#{provider.symbol}.magic", provider: provider, password: ENV['MDS_PASSWORD']) }

      # attributes MUST be empty
      let(:valid_attributes) {file_fixture('transfer.json').read }

      before { put "/dois/#{doi.doi}", params: valid_attributes, headers: provider_headers }

      it 'returns no errors' do
        expect(response).to have_http_status(403)
      end
    end

    context 'passes when we transfer a DOI as provider' do
      let(:provider_bearer) { User.generate_token(uid: "datacite", role_id: "provider_admin", name: "DataCite", email:"support@datacite.org", provider_id: "datacite") }
      let(:provider_headers) { {'ACCEPT'=>'application/vnd.api+json', 'CONTENT_TYPE'=>'application/vnd.api+json', 'Authorization' => 'Bearer ' + provider_bearer}}

      let(:doi) { create(:doi, client: client) }
      let(:new_client) { create(:client, symbol: "#{provider.symbol}.magic", provider: provider, password: ENV['MDS_PASSWORD']) }

      # attributes MUST be empty
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "mode" => "transfer"
            },
            "relationships"=> {
              "client"=>  {
                "data"=> {
                  "type"=> "clients",
                  "id"=> new_client.symbol.downcase
                }
              }
            }
          }
        }
      end

      before { put "/dois/#{doi.doi}", params: valid_attributes.to_json, headers: provider_headers }

      it 'returns no errors' do
        expect(response).to have_http_status(200)
        expect(json.dig('data', 'attributes', 'doi')).to eq(doi.doi.downcase)
      end

      it 'updates the client id' do
        # TODO: db-fields-for-attributes relates to delay in Elasticsearch indexing
        # expect(json.dig('data', 'relationships', 'client','data','id')).to eq(new_client.symbol.downcase)
        # expect(json.dig('data', 'attributes', 'titles')).to eq(doi.titles)
      end
    end

    context 'when we transfer a DOI as staff' do
      let(:doi) { create(:doi, doi: "10.14454/119495", client: client, aasm_state: "registered") }
      let(:new_client) { create(:client, symbol: "#{provider.symbol}.magic", provider: provider, password: ENV['MDS_PASSWORD']) }
      let(:xml) { Base64.strict_encode64(file_fixture('datacite.xml').read) }
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "url" => "http://www.bl.uk/pdf/pat.pdf",
              "xml" => xml
            },
            "relationships"=> {
              "client"=>  {
                "data"=> {
                  "type"=> "clients",
                  "id"=> new_client.symbol.downcase
                }
              }
            }
          }
        }
      end

      before { put "/dois/#{doi.doi}", params: valid_attributes.to_json, headers: admin_headers }

      it 'returns no errors' do
        expect(response).to have_http_status(200)
        expect(json.dig('data', 'attributes', 'doi')).to eq(doi.doi)
      end

      it 'updates the client id' do
        # TODO: db-fields-for-attributes relates to delay in Elasticsearch indexing
        expect(json.dig('data', 'relationships', 'client','data','id')).to eq(new_client.symbol.downcase)
      end
    end

    context 'when the resource_type_general changes' do
      let(:xml) { Base64.strict_encode64(file_fixture('datacite.xml').read) }
      let(:types) { { "resourceTypeGeneral" => "DataPaper", "resourceType" => "BlogPosting" } }
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "url" => "http://www.bl.uk/pdf/pat.pdf",
              "xml" => xml,
              "types" => types,
              "event" => "publish"
            }
          }
        }
      end
      before { patch "/dois/#{doi.doi}", params: valid_attributes.to_json, headers: headers }

      it 'updates the record' do
        expect(json.dig('data', 'attributes', 'url')).to eq("http://www.bl.uk/pdf/pat.pdf")
        expect(json.dig('data', 'attributes', 'doi')).to eq(doi.doi.downcase)
        expect(json.dig('data', 'attributes', 'types')).to eq("resourceType"=>"BlogPosting", "resourceTypeGeneral"=>"DataPaper")
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end

      it 'sets state to findable' do
        expect(json.dig('data', 'attributes', 'state')).to eq("findable")
      end
    end
  end

  describe 'POST /dois' do
    context 'when the request is valid' do
      let(:xml) { Base64.strict_encode64(file_fixture('datacite.xml').read) }
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "doi" => "10.14454/10703",
              "url" => "http://www.bl.uk/pdf/patspec.pdf",
              "xml" => xml,
              "source" => "test",
              "event" => "publish"
            }
          }
        }
      end

      before { post '/dois', params: valid_attributes.to_json, headers: headers }

      it 'creates a Doi' do
        expect(json.dig('data', 'attributes', 'url')).to eq("http://www.bl.uk/pdf/patspec.pdf")
        expect(json.dig('data', 'attributes', 'doi')).to eq("10.14454/10703")
        expect(json.dig('data', 'attributes', 'titles')).to eq([{"title"=>"Eating your own Dog Food"}])
        expect(json.dig('data', 'attributes', 'creators')).to eq([{"familyName"=>"Fenner", "givenName"=>"Martin", "id"=>"https://orcid.org/0000-0003-1419-2405", "name"=>"Fenner, Martin", "type"=>"Person"}])
        expect(json.dig('data', 'attributes', 'schemaVersion')).to eq("http://datacite.org/schema/kernel-4")
        expect(json.dig('data', 'attributes', 'source')).to eq("test")
        expect(json.dig('data', 'attributes', 'types')).to eq("bibtex"=>"article", "citeproc"=>"article-journal", "resourceType"=>"BlogPosting", "resourceTypeGeneral"=>"Text", "ris"=>"RPRT", "schemaOrg"=>"ScholarlyArticle")
        
        doc = Nokogiri::XML(Base64.decode64(json.dig('data', 'attributes', 'xml')), nil, 'UTF-8', &:noblanks)
        expect(doc.at_css("identifier").content).to eq("10.14454/10703")
      end

      it 'returns status code 201' do
        puts response.body
        expect(response).to have_http_status(201)
      end

      it 'sets state to findable' do
        expect(json.dig('data', 'attributes', 'state')).to eq("findable")
      end
    end

    context 'when the request is valid with attributes' do
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "doi" => "10.14454/10703",
              "url" => "http://www.bl.uk/pdf/patspec.pdf",
              "types" => { "bibtex"=>"article", "citeproc"=>"article-journal", "resourceType"=>"BlogPosting", "resourceTypeGeneral"=>"Text", "ris"=>"RPRT", "schemaOrg"=>"ScholarlyArticle" },
              "titles" => [{"title"=>"Eating your own Dog Food"}],
              "publisher" => "DataCite",
              "publicationYear" => 2016,
              "creators" => [{"familyName"=>"Fenner", "givenName"=>"Martin", "id"=>"https://orcid.org/0000-0003-1419-2405", "name"=>"Fenner, Martin", "type"=>"Person"}],
              "source" => "test",
              "event" => "publish"
            }
          }
        }
      end

      before { post '/dois', params: valid_attributes.to_json, headers: headers }

      it 'creates a Doi' do
        expect(json.dig('data', 'attributes', 'url')).to eq("http://www.bl.uk/pdf/patspec.pdf")
        expect(json.dig('data', 'attributes', 'doi')).to eq("10.14454/10703")
        expect(json.dig('data', 'attributes', 'titles')).to eq([{"title"=>"Eating your own Dog Food"}])
        expect(json.dig('data', 'attributes', 'creators')).to eq( [{"familyName"=>"Fenner", "givenName"=>"Martin", "id"=>"https://orcid.org/0000-0003-1419-2405", "name"=>"Fenner, Martin", "type"=>"Person"}])
        expect(json.dig('data', 'attributes', 'publisher')).to eq("DataCite")
        expect(json.dig('data', 'attributes', 'publicationYear')).to eq(2016)
        # expect(json.dig('data', 'attributes', 'schemaVersion')).to eq("http://datacite.org/schema/kernel-4")
        expect(json.dig('data', 'attributes', 'source')).to eq("test")
        expect(json.dig('data', 'attributes', 'types')).to eq("bibtex"=>"article", "citeproc"=>"article-journal", "resourceType"=>"BlogPosting", "resourceTypeGeneral"=>"Text", "ris"=>"RPRT", "schemaOrg"=>"ScholarlyArticle")
        doc = Nokogiri::XML(Base64.decode64(json.dig('data', 'attributes', 'xml')), nil, 'UTF-8', &:noblanks)
        expect(doc.at_css("identifier").content).to eq("10.14454/10703")
      end

      it 'returns status code 201' do
        expect(response).to have_http_status(201)
      end

      it 'sets state to findable' do
        expect(json.dig('data', 'attributes', 'state')).to eq("findable")
      end
    end

    context 'schema_org' do
      let(:xml) { Base64.strict_encode64(file_fixture('schema_org_topmed.json').read) }
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "url" => "https://ors.datacite.org/doi:/10.14454/8na3-9s47",
              "xml" => xml,
              "source" => "test",
              "event" => "publish"
            }
          }
        }
      end

      before { patch "/dois/10.14454/8na3-9s47", params: valid_attributes.to_json, headers: headers }

      # TODO register media
      # it 'updates the record' do
      #   expect(json.dig('data', 'attributes', 'url')).to eq("http://www.bl.uk/pdf/pat.pdf")
      #   expect(json.dig('data', 'attributes', 'doi')).to eq(doi.doi.downcase)
      #   expect(json.dig('data', 'attributes', 'title')).to eq("Eating your own Dog Food")

      #   xml = Maremma.from_xml(Base64.decode64(json.dig('data', 'attributes', 'xml'))).fetch("resource", {})
      #   expect(xml.dig("titles", "title")).to eq("Eating your own Dog Food")
      # end

      # it 'returns status code 200' do
      #   expect(response).to have_http_status(200)
      # end

      # it 'sets state to findable' do
      #   expect(json.dig('data', 'attributes', 'state')).to eq("findable")
      # end
    end

    context 'when the request uses schema 3' do
      let(:xml) { Base64.strict_encode64(file_fixture('datacite_schema_3.xml').read) }
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "doi" => "10.14454/10703",
              "url" => "http://www.bl.uk/pdf/patspec.pdf",
              "xml" => xml,
              "source" => "test",
              "event" => "publish"
            },
            "relationships"=> {
              "client"=>  {
                "data"=> {
                  "type"=> "clients",
                  "id"=> client.symbol.downcase
                }
              }
            }
          }
        }
      end

      before { post '/dois', params: valid_attributes.to_json, headers: headers }

      it 'creates a Doi' do
        expect(json.dig('data', 'attributes', 'url')).to eq("http://www.bl.uk/pdf/patspec.pdf")
        expect(json.dig('data', 'attributes', 'doi')).to eq("10.14454/10703")
        expect(json.dig('data', 'attributes', 'titles')).to eq([{"title"=>"Data from: A new malaria agent in African hominids."}])
        expect(json.dig('data', 'attributes', 'source')).to eq("test")
        expect(json.dig('data', 'attributes', 'schemaVersion')).to eq("http://datacite.org/schema/kernel-3")
      end

      it 'returns status code 201' do
        expect(response).to have_http_status(201)
      end

      it 'sets state to findable' do
        expect(json.dig('data', 'attributes', 'state')).to eq("findable")
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

    #   before { post '/dois', params: valid_attributes.to_json, headers: headers }

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

    context 'when the request uses namespaced xml' do
      let(:xml) { Base64.strict_encode64(file_fixture('ns0.xml').read) }
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "doi" => "10.14454/10703",
              "url" => "http://www.bl.uk/pdf/patspec.pdf",
              "xml" => xml,
              "event" => "publish"
            }
          }
        }
      end

      before { post '/dois', params: valid_attributes.to_json, headers: headers }

      it 'creates a Doi' do
        expect(json.dig('data', 'attributes', 'doi')).to eq("10.14454/10703")
        expect(json.dig('data', 'attributes', 'titles')).to eq([{"title"=>"LAMMPS Data-File Generator"}])
        expect(json.dig('data', 'attributes', 'schemaVersion')).to eq("http://datacite.org/schema/kernel-2.2")
      end

      it 'returns status code 201' do
        expect(response).to have_http_status(201)
      end

      it 'sets state to findable' do
        expect(json.dig('data', 'attributes', 'state')).to eq("findable")
      end
    end

    context 'when the request uses schema 4.0' do
      let(:xml) { Base64.strict_encode64(file_fixture('schema_4.0.xml').read) }
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "doi" => "10.14454/10703",
              "url" => "http://www.bl.uk/pdf/patspec.pdf",
              "xml" => xml,
              "event" => "publish"
            }
          }
        }
      end

      before { post '/dois', params: valid_attributes.to_json, headers: headers }

      it 'creates a Doi' do
        expect(json.dig('data', 'attributes', 'doi')).to eq("10.14454/10703")
        expect(json.dig('data', 'attributes', 'titles')).to eq([{"title"=>"Southern Sierra Critical Zone Observatory (SSCZO), Providence Creek\n      meteorological data, soil moisture and temperature, snow depth and air\n      temperature"}])
        expect(json.dig('data', 'attributes', 'schemaVersion')).to eq("http://datacite.org/schema/kernel-4")
      end

      it 'returns status code 201' do
        expect(response).to have_http_status(201)
      end

      it 'sets state to findable' do
        expect(json.dig('data', 'attributes', 'state')).to eq("findable")
      end
    end

    context 'when the request uses namespaced xml' do
      let(:xml) { Base64.strict_encode64(file_fixture('ns0.xml').read) }
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "doi" => "10.14454/10703",
              "url" => "http://www.bl.uk/pdf/patspec.pdf",
              "xml" => xml,
              "event" => "publish"
            }
          }
        }
      end

      before { post '/dois', params: valid_attributes.to_json, headers: headers }

      it 'creates a Doi' do
        expect(json.dig('data', 'attributes', 'doi')).to eq("10.14454/10703")
        expect(json.dig('data', 'attributes', 'titles')).to eq([{"title"=>"LAMMPS Data-File Generator"}])
        expect(json.dig('data', 'attributes', 'schemaVersion')).to eq("http://datacite.org/schema/kernel-2.2")
      end

      it 'returns status code 201' do
        puts response.status
        expect(response).to have_http_status(201)
      end

      it 'sets state to findable' do
        expect(json.dig('data', 'attributes', 'state')).to eq("findable")
      end
    end

    context 'when the title changes' do
      let(:titles) { { "title" => "Referee report. For: RESEARCH-3482 [version 5; referees: 1 approved, 1 approved with reservations]" } }
      let(:xml) { Base64.strict_encode64(file_fixture('datacite.xml').read) }
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
              "event" => "publish"
            }
          }
        }
      end

      before { post '/dois', params: valid_attributes.to_json, headers: headers }

      it 'creates a Doi' do
        expect(json.dig('data', 'attributes', 'doi')).to eq("10.14454/10703")
        expect(json.dig('data', 'attributes', 'titles')).to eq("title"=>"Referee report. For: RESEARCH-3482 [version 5; referees: 1 approved, 1 approved with reservations]")
        expect(json.dig('data', 'attributes', 'url')).to eq("http://www.bl.uk/pdf/patspec.pdf")
        expect(json.dig('data', 'attributes', 'source')).to eq("test")
      end

      it 'returns status code 201' do
        expect(response).to have_http_status(201)
      end

      it 'sets state to findable' do
        expect(json.dig('data', 'attributes', 'state')).to eq("findable")
      end
    end

    context 'when the url changes ftp url' do
      let(:url) { "ftp://ftp.library.noaa.gov/noaa_documents.lib/NOS/NGS/TM_NOS_NGS/TM_NOS_NGS_72.pdf" }
      let(:xml) { Base64.strict_encode64(file_fixture('datacite.xml').read) }
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "doi" => "10.14454/10703",
              "url" => url,
              "xml" => xml,
              "event" => "publish"
            }
          }
        }
      end

      before { post '/dois', params: valid_attributes.to_json, headers: headers }

      it 'creates a Doi' do
        expect(json.dig('data', 'attributes', 'doi')).to eq("10.14454/10703")
        expect(json.dig('data', 'attributes', 'url')).to eq(url)
      end

      it 'returns status code 201' do
        expect(response).to have_http_status(201)
      end

      it 'sets state to findable' do
        expect(json.dig('data', 'attributes', 'state')).to eq("findable")
      end
    end

    context 'when the titles changes to nil' do
      let(:xml) { Base64.strict_encode64(file_fixture('datacite.xml').read) }
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "doi" => "10.14454/10703",
              "url" => "http://www.bl.uk/pdf/patspec.pdf",
              "xml" => xml,
              "titles" => nil,
              "event" => "publish"
            }
          }
        }
      end

      before { post '/dois', params: valid_attributes.to_json, headers: headers }

      it 'creates a Doi' do
        expect(json.dig('data', 'attributes', 'doi')).to eq("10.14454/10703")
        expect(json.dig('data', 'attributes', 'titles')).to eq([{"title"=>"Eating your own Dog Food"}])
        expect(json.dig('data', 'attributes', 'url')).to eq("http://www.bl.uk/pdf/patspec.pdf")
      end

      it 'returns status code 201' do

        expect(response).to have_http_status(201)
      end

      it 'sets state to findable' do
        expect(json.dig('data', 'attributes', 'state')).to eq("findable")
      end
    end

    context 'when the titles changes to blank' do
      let(:xml) { Base64.strict_encode64(file_fixture('datacite.xml').read) }
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "doi" => "10.14454/10703",
              "url" => "http://www.bl.uk/pdf/patspec.pdf",
              "xml" => xml,
              "titles" => nil,
              "event" => "publish"
            }
          }
        }
      end

      before { post '/dois', params: valid_attributes.to_json, headers: headers }

      it 'creates a Doi' do
        expect(json.dig('data', 'attributes', 'doi')).to eq("10.14454/10703")
        expect(json.dig('data', 'attributes', 'titles')).to eq([{"title"=>"Eating your own Dog Food"}])
        expect(json.dig('data', 'attributes', 'url')).to eq("http://www.bl.uk/pdf/patspec.pdf")
      end

      it 'returns status code 201' do
        expect(response).to have_http_status(201)
      end

      it 'sets state to findable' do
        expect(json.dig('data', 'attributes', 'state')).to eq("findable")
      end
    end

    context 'when the creators change' do
      let(:creators) { [{ "name"=>"Ollomi, Benjamin" }, { "name"=>"Duran, Patrick" }] }
      let(:xml) { Base64.strict_encode64(file_fixture('datacite.xml').read) }
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "doi" => "10.14454/10703",
              "url" => "http://www.bl.uk/pdf/patspec.pdf",
              "xml" => xml,
              "creators" => creators,
              "event" => "publish"
            }
          }
        }
      end

      before { post '/dois', params: valid_attributes.to_json, headers: headers }

      it 'creates a Doi' do
        expect(json.dig('data', 'attributes', 'doi')).to eq("10.14454/10703")
        expect(json.dig('data', 'attributes', 'creators')).to eq(creators)
        expect(json.dig('data', 'attributes', 'url')).to eq("http://www.bl.uk/pdf/patspec.pdf")
      end

      it 'returns status code 201' do
        expect(response).to have_http_status(201)
      end

      it 'sets state to findable' do
        expect(json.dig('data', 'attributes', 'state')).to eq("findable")
      end
    end

    context 'creators no xml' do
      let(:creators) { [{ "name"=>"Ollomi, Benjamin" }, { "name"=>"Duran, Patrick" }] }
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "doi" => "10.14454/10703",
              "url" => "http://www.bl.uk/pdf/patspec.pdf",
              "xml" => nil,
              "creators" => creators,
              "event" => "publish"
            }
          }
        }
      end

      before { post '/dois', params: valid_attributes.to_json, headers: headers }

      it 'returns validation error' do
        expect(json.dig('errors')).to eq([{"source"=>"metadata", "title"=>"Is invalid"}, {"source"=>"metadata", "title"=>"Is invalid"}])
      end

      it 'returns status code 422' do
        expect(response).to have_http_status(422)
      end
    end

    context 'state change with test prefix' do
      let(:prefix) { create(:prefix, prefix: "10.5072") }
      let!(:client_prefix) { create(:client_prefix, client: client, prefix: prefix) }

      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "doi" => "10.5072/10704",
              "url" => "http://www.bl.uk/pdf/patspec.pdf",
              "event" => "publish"
            }
          }
        }
      end
      before { post '/dois', params: valid_attributes.to_json, headers: headers }

      it 'creates a Doi' do
        expect(json.dig('data', 'attributes', 'url')).to eq("http://www.bl.uk/pdf/patspec.pdf")
        expect(json.dig('data', 'attributes', 'doi')).to eq("10.5072/10704")
      end

      it 'returns status code 201' do
        expect(response).to have_http_status(201)
      end

      it 'sets state to draft' do
        expect(json.dig('data', 'attributes', 'state')).to eq("draft")
      end
    end

    context 'when the request is invalid' do
      let(:not_valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "doi" => "10.aaaa03",
              "url"=> "http://www.bl.uk/pdf/patspec.pdf",
            }
          }
        }
      end
      before { post '/dois', params: not_valid_attributes.to_json, headers: headers }

      it 'returns status code 403' do
        expect(response).to have_http_status(403)
      end

      it 'returns a validation failure message' do
        expect(json["errors"]).to eq([{"status"=>"403", "title"=>"You are not authorized to access this resource."}])
      end
    end

    context 'when the xml is invalid draft doi' do
      let(:xml) { Base64.strict_encode64(file_fixture('datacite_missing_creator.xml').read) }
      let(:not_valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "doi" => "10.14454/10703",
              "url"=> "http://www.bl.uk/pdf/patspec.pdf",
              "xml" => xml
            }
          }
        }
      end
      before { post '/dois', params: not_valid_attributes.to_json, headers: headers }

      it 'returns status code 201' do
        expect(response).to have_http_status(201)
      end

      it 'creates a Doi' do
        expect(json.dig('data', 'attributes', 'doi')).to eq("10.14454/10703")
        expect(json.dig('data', 'attributes', 'titles')).to eq([{"title"=>"Eating your own Dog Food"}])
        expect(json.dig('data', 'attributes', 'url')).to eq("http://www.bl.uk/pdf/patspec.pdf")
        expect(json.dig('data', 'attributes', 'creators')).to be_blank
      end
    end

    context 'when the xml is invalid' do
      let(:xml) { Base64.strict_encode64(file_fixture('datacite_missing_creator.xml').read) }
      let(:not_valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "doi" => "10.14454/4K3M-NYVG",
              "url"=> "http://www.bl.uk/pdf/patspec.pdf",
              "xml" => xml,
              "event" => "publish"
            }
          }
        }
      end
      before { post '/dois', params: not_valid_attributes.to_json, headers: headers }

      it 'returns status code 422' do
        expect(response).to have_http_status(422)
      end

      it 'returns a validation failure message' do
        expect(json["errors"]).to eq([{"source"=>"creators", "title"=>"Missing child element(s). expected is ( {http://datacite.org/schema/kernel-4}creator ). at line 4, column 0"}])
      end
    end

    describe 'POST /dois/validate' do
      context 'validates' do
        let(:xml) { ::Base64.strict_encode64(File.read(file_fixture('datacite.xml'))) }
        let(:params) do
          {
            "data" => {
              "type" => "dois",
              "attributes" => {
                "doi" => "10.14454/10703",
                "xml" => xml,
              }
            }
          }
        end

        before { post '/dois/validate', params: params.to_json, headers: headers }

        it 'validates a Doi' do
          expect(json.dig('data', 'attributes', 'doi')).to eq("10.14454/10703")
          expect(json.dig('data', 'attributes', 'titles')).to eq([{"title"=>"Eating your own Dog Food"}])
          expect(json.dig('data', 'attributes', 'dates')).to eq([{"date"=>"2016-12-20", "dateType"=>"Created"}, {"date"=>"2016-12-20", "dateType"=>"Issued"}, {"date"=>"2016-12-20", "dateType"=>"Updated"}])
        end

        it 'returns status code 200' do
          expect(response).to have_http_status(200)
        end
      end

      context 'validates schema 3' do
        let(:xml) { ::Base64.strict_encode64(File.read(file_fixture('datacite_schema_3.xml'))) }
        let(:params) do
          {
            "data" => {
              "type" => "dois",
              "attributes" => {
                "doi" => "10.14454/10703",
                "xml" => xml,
              }
            }
          }
        end

        before { post '/dois/validate', params: params.to_json, headers: headers }

        it 'validates a Doi' do
          expect(json.dig('data', 'attributes', 'doi')).to eq("10.14454/10703")
          expect(json.dig('data', 'attributes', 'titles')).to eq([{"title"=>"Data from: A new malaria agent in African hominids."}])
          expect(json.dig('data', 'attributes', 'dates')).to eq([{"date"=>"2011", "dateType"=>"Issued"}])
        end

        it 'returns status code 200' do
          expect(response).to have_http_status(200)
        end
      end

      context 'when the creators are missing' do
        let(:xml) { ::Base64.strict_encode64(File.read(file_fixture('datacite_missing_creator.xml'))) }
        let(:params) do
          {
            "data" => {
              "type" => "dois",
              "attributes" => {
                "doi" => "10.14454/10703",
                "xml" => xml
              }
            }
          }
        end

        before { post '/dois/validate', params: params.to_json, headers: headers }

        it 'validates a Doi' do
          expect(json['errors'].size).to eq(1)
          expect(json['errors'].first).to eq("source"=>"creators", "title"=>"Missing child element(s). expected is ( {http://datacite.org/schema/kernel-4}creator ). at line 4, column 0")
        end

        it 'returns status code 200' do
          expect(response).to have_http_status(200)
        end
      end

      context 'when the creators are malformed' do
        let(:xml) { ::Base64.strict_encode64(File.read(file_fixture('datacite_malformed_creator.xml'))) }
        let(:params) do
          {
            "data" => {
              "type" => "dois",
              "attributes" => {
                "doi" => "10.14454/10703",
                "xml" => xml,
              }
            }
          }
        end

        before { post '/dois/validate', params: params.to_json, headers: headers }

        it 'validates a Doi' do
          expect(json['errors'].size).to eq(1)
          expect(json['errors'].first).to eq("source"=>"creatorName", "title"=>"This element is not expected. expected is ( {http://datacite.org/schema/kernel-4}affiliation ). at line 16, column 0")
        end

        it 'returns status code 200' do
          expect(response).to have_http_status(200)
        end
      end

      context 'validates citeproc' do
        let(:xml) { ::Base64.strict_encode64(File.read(file_fixture('citeproc.json'))) }
        let(:params) do
          {
            "data" => {
              "type" => "dois",
              "attributes" => {
                "doi" => "10.14454/10703",
                "xml" => xml,
              }
            }
          }
        end

        before { post '/dois/validate', params: params.to_json, headers: headers }

        it 'validates a Doi' do
          expect(json.dig('data', 'attributes', 'doi')).to eq("10.14454/10703")
          expect(json.dig('data', 'attributes', 'titles')).to eq([{"title"=>"Eating your own Dog Food"}])
          expect(json.dig('data', 'attributes', 'dates')).to eq([{"date"=>"2016-12-20", "dateType"=>"Issued"}])
        end

        it 'returns status code 200' do
          expect(response).to have_http_status(200)
        end
      end

      context 'validates codemeta' do
        let(:xml) { ::Base64.strict_encode64(File.read(file_fixture('codemeta.json'))) }
        let(:params) do
          {
            "data" => {
              "type" => "dois",
              "attributes" => {
                "doi" => "10.14454/10703",
                "xml" => xml,
              }
            }
          }
        end

        before { post '/dois/validate', params: params.to_json, headers: headers }

        it 'validates a Doi' do
          expect(json.dig('data', 'attributes', 'doi')).to eq("10.14454/10703")
          expect(json.dig('data', 'attributes', 'titles')).to eq([{"title"=>"R Interface to the DataONE REST API"}])
          expect(json.dig('data', 'attributes', 'dates')).to eq([{"date"=>"2016-05-27", "dateType"=>"Issued"}, {"date"=>"2016-05-27", "dateType"=>"Created"}, {"date"=>"2016-05-27", "dateType"=>"Updated"}])
        end

        it 'returns status code 200' do
          expect(response).to have_http_status(200)
        end
      end

      context 'validates crosscite' do
        let(:xml) { ::Base64.strict_encode64(File.read(file_fixture('crosscite.json'))) }
        let(:params) do
          {
            "data" => {
              "type" => "dois",
              "attributes" => {
                "doi" => "10.14454/10703",
                "xml" => xml,
              }
            }
          }
        end

        before { post '/dois/validate', params: params.to_json, headers: headers }

        it 'validates a Doi' do
          expect(json.dig('data', 'attributes', 'doi')).to eq("10.14454/10703")
          expect(json.dig('data', 'attributes', 'titles')).to eq([{"title"=>"Analysis Tools for Crossover Experiment of UI using Choice Architecture"}])
          expect(json.dig('data', 'attributes', 'dates')).to eq("date"=>"2016-03-27", "dateType"=>"Issued")
        end

        it 'returns status code 200' do
          expect(response).to have_http_status(200)
        end
      end

      context 'validates bibtex' do
        let(:xml) { ::Base64.strict_encode64(File.read(file_fixture('crossref.bib'))) }
        let(:params) do
          {
            "data" => {
              "type" => "dois",
              "attributes" => {
                "doi" => "10.14454/10703",
                "xml" => xml,
              }
            }
          }
        end

        before { post '/dois/validate', params: params.to_json, headers: headers }

        it 'validates a Doi' do
          expect(json.dig('data', 'attributes', 'doi')).to eq("10.14454/10703")
          expect(json.dig('data', 'attributes', 'titles')).to eq([{"title"=>"Automated quantitative histology reveals vascular morphodynamics during Arabidopsis hypocotyl secondary growth"}])
          expect(json.dig('data', 'attributes', 'dates')).to eq([{"date"=>"2014", "dateType"=>"Issued"}])
        end

        it 'returns status code 200' do
          expect(response).to have_http_status(200)
        end
      end

      context 'validates ris' do
        let(:xml) { ::Base64.strict_encode64(File.read(file_fixture('crossref.ris'))) }
        let(:params) do
          {
            "data" => {
              "type" => "dois",
              "attributes" => {
                "doi" => "10.14454/10703",
                "xml" => xml
              }
            }
          }
        end

        before { post '/dois/validate', params: params.to_json, headers: headers }

        it 'validates a Doi' do
          expect(json.dig('data', 'attributes', 'doi')).to eq("10.14454/10703")
          expect(json.dig('data', 'attributes', 'titles')).to eq([{"title"=>"Automated quantitative histology reveals vascular morphodynamics during Arabidopsis hypocotyl secondary growth"}])
          expect(json.dig('data', 'attributes', 'dates')).to eq([{"date"=>"2014", "dateType"=>"Issued"}])
        end

        it 'returns status code 200' do
          expect(response).to have_http_status(200)
        end
      end

      context 'validates crossref xml' do
        let(:xml) { ::Base64.strict_encode64(File.read(file_fixture('crossref.xml'))) }
        let(:params) do
          {
            "data" => {
              "type" => "dois",
              "attributes" => {
                "doi" => "10.14454/10703",
                "xml" => xml,
              }
            }
          }
        end

        before { post '/dois/validate', params: params.to_json, headers: headers }

        it 'validates a Doi' do
          expect(json.dig('data', 'attributes', 'doi')).to eq("10.14454/10703")
          expect(json.dig('data', 'attributes', 'titles')).to eq([{"title"=>"Triose Phosphate Isomerase Deficiency Is Caused by Altered Dimerization–Not Catalytic Inactivity–of the Mutant Enzymes"}])
          expect(json.dig('data', 'attributes', 'dates')).to eq([{"date"=>"2006-12-20", "dateType"=>"Issued"}, {"date"=>"2017-01-01T03:37:08Z", "dateType"=>"Updated"}])
        end

        it 'returns status code 200' do
          expect(response).to have_http_status(200)
        end
      end

      context 'validates schema.org' do
        let(:xml) { ::Base64.strict_encode64(File.read(file_fixture('schema_org.json'))) }
        let(:params) do
          {
            "data" => {
              "type" => "dois",
              "attributes" => {
                "doi" => "10.14454/10703",
                "xml" => xml,
              }
            }
          }
        end

        before { post '/dois/validate', params: params.to_json, headers: headers }

        it 'validates a Doi' do
          expect(json.dig('data', 'attributes', 'doi')).to eq("10.14454/10703")
          expect(json.dig('data', 'attributes', 'titles')).to eq([{"title"=>"Eating your own Dog Food"}])
          expect(json.dig('data', 'attributes', 'dates')).to eq([{"date"=>"2016-12-20", "dateType"=>"Issued"}, {"date"=>"2016-12-20", "dateType"=>"Created"}, {"date"=>"2016-12-20", "dateType"=>"Updated"}])
        end

        it 'returns status code 200' do
          expect(response).to have_http_status(200)
        end
      end
    end

    context 'landing page' do
      let(:url) { "https://blog.datacite.org/re3data-science-europe/" }
      let(:xml) { Base64.strict_encode64(file_fixture('datacite.xml').read) }
      let(:landingPage) { {
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
        "bodyHasPid" => true
      } }
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "doi" => "10.14454/10703",
              "url" => url,
              "xml" => xml,
              "landingPage" => landingPage,
              "event" => "publish"
            }
          }
        }
      end

      before { post '/dois', params: valid_attributes.to_json, headers: headers }

      it 'creates a doi' do
        puts json.dig('data', 'attributes')
        expect(json.dig('data', 'attributes', 'url')).to eq(url)
        expect(json.dig('data', 'attributes', 'doi')).to eq("10.14454/10703")
        expect(json.dig('data', 'attributes', 'landingPage')).to eq(landingPage)
      end

      it 'returns status code 201' do
        expect(response).to have_http_status(201)
      end

      it 'sets state to registered' do
        expect(json.dig('data', 'attributes', 'state')).to eq("findable")
      end
    end

    context 'landing page schema-org-id hash' do
      let(:url) { "https://blog.datacite.org/re3data-science-europe/" }
      let(:xml) { Base64.strict_encode64(file_fixture('datacite.xml').read) }
      let(:landingPage) { {
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
          {
            "@type" => "PropertyValue",
            "value" => "http://dx.doi.org/10.4225/06/564AB348340D5",
            "propertyID" => "URL"
          }
        ],
        "dcIdentifier" => nil,
        "citationDoi" => nil,
        "bodyHasPid" => true
      } }
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "doi" => "10.14454/10703",
              "url" => url,
              "xml" => xml,
              "landingPage" => landingPage,
              "event" => "publish"
            }
          }
        }
      end

      before { post '/dois', params: valid_attributes.to_json, headers: headers }

      it 'creates a Doi' do
        expect(json.dig('data', 'attributes', 'url')).to eq(url)
        expect(json.dig('data', 'attributes', 'doi')).to eq("10.14454/10703")
        expect(json.dig('data', 'attributes', 'landingPage')).to eq(landingPage)
      end

      it 'returns status code 201' do
        expect(response).to have_http_status(201)
      end

      it 'sets state to findable' do
        expect(json.dig('data', 'attributes', 'state')).to eq("findable")
      end
    end
  end

  describe 'DELETE /dois/:id' do
    before do
      doi = create(:doi, client: client, aasm_state: "draft")
      sleep 1
      delete "/dois/#{doi.doi}", headers: headers
    end

    it 'returns status code 204' do
      expect(response).to have_http_status(204)
    end

    it 'deletes the record' do
      expect(response.body).to be_empty
    end
  end

  describe 'DELETE /dois/:id findable state' do
    before do
      doi = create(:doi, client: client, aasm_state: "findable")
      delete "/dois/#{doi.doi}", headers: headers
    end

    it 'returns status code 405' do
      expect(response).to have_http_status(405)
    end

    it 'deletes the record' do
      expect(json["errors"]).to eq([{"status"=>"405", "title"=>"Method not allowed"}])
    end
  end

  describe 'POST /dois/set-state' do
    before { post '/dois/set-state', headers: admin_headers }

    it 'returns dois' do
      expect(json['message']).to eq("DOI state updated.")
    end

    it 'returns status code 200' do
      expect(response).to have_http_status(200)
    end
  end

  describe 'POST /dois/set-minted' do
    let(:provider)  { create(:provider, symbol: "ETHZ") }
    let(:client)  { create(:client, provider: provider) }
    let!(:dois) { create_list(:doi, 10, client: client) }

    before { post '/dois/set-minted', headers: admin_headers }

    it 'returns dois' do
      expect(json['message']).to eq("DOI minted timestamp added.")
    end

    it 'returns status code 200' do
      expect(response).to have_http_status(200)
    end
  end

  describe 'POST /dois/set-url' do
    let!(:dois) { create_list(:doi, 3, client: client, url: nil) }

    before { post '/dois/set-url', headers: admin_headers }

    it 'returns dois' do
      expect(json['message']).to eq("Adding missing URLs queued.")
    end

    it 'returns status code 200' do
      expect(response).to have_http_status(200)
    end
  end

  describe 'POST /dois/delete-test-dois' do
    before { post '/dois/delete-test-dois', headers: admin_headers }

    it 'returns dois' do
      expect(json['message']).to eq("Test DOIs deleted.")
    end

    it 'returns status code 200' do
      expect(response).to have_http_status(200)
    end
  end

  describe 'GET /dois/random' do
    before { get '/dois/random', headers: headers }

    it 'returns random doi' do
      expect(json['doi']).to start_with("10.5072")
      expect(response).to have_http_status(200)
    end

    it 'returns status code 200' do
      expect(response).to have_http_status(200)
    end
  end

  describe 'GET /dois/<doi> linkcheck results' do
    let(:landing_page) { {
      "checked" => Time.zone.now.utc.iso8601,
      "status" => 200,
      "url" => "http://example.com",
      "contentType" => "text/html",
      "error" => nil,
      "redirectCount" => 0,
      "redirectUrls" => [],
      "downloadLatency" => 200,
      "hasSchemaOrg" => true,
      "schemaOrgId" => "10.14454/10703",
      "dcIdentifier" => nil,
      "citationDoi" => nil,
      "bodyHasPid" => true
    } }

    # Setup an initial DOI with results will check permissions against.
    let(:doi) {
      create(
        :doi, doi: "10.24425/2210181332",
        client: client,
        state: "findable",
        event: 'publish',
        landing_page: landing_page
        )
    }

    # Create a different dummy client and a doi with entry associated
    # This is so we can test clients accessing others information
    let(:other_client) { create(:client, provider: provider, symbol: 'DATACITE.DOESNTEXIST', password: 'notarealpassword') }
    let(:other_doi) {
      create(
        :doi, doi: "10.24425/2210181332",
        client: other_client,
        state: "findable",
        event: 'publish',
        landing_page: landing_page
        )
    }

    context 'anonymous get' do
      let(:headers) { { 'ACCEPT'=>'application/vnd.api+json', 'CONTENT_TYPE'=>'application/vnd.api+json' } }
      before { get "/dois/#{doi.doi}", headers: headers}

      it 'returns without landing page results' do
        expect(json.dig('data', 'attributes', 'doi')).to eq(doi.doi)
        expect(json.dig('data', 'attributes', 'landingPage')).to eq(nil)
      end
    end

    context 'client authorised get own dois' do
      let(:bearer) { User.generate_token(role_id: "client_admin", client_id: client.symbol.downcase) }
      let(:headers) { { 'ACCEPT'=>'application/vnd.api+json', 'CONTENT_TYPE'=>'application/vnd.api+json', 'Authorization' => 'Bearer ' + bearer } }

      before { get "/dois/#{doi.doi}", headers: headers }

      it 'returns with landing page results' do
        expect(json.dig('data', 'attributes', 'doi')).to eq(doi.doi)
        expect(json.dig('data', 'attributes', 'landingPage')).to eq(landing_page)
      end
    end


    context 'client authorised try get diff dois landing data' do
      let(:bearer) { User.generate_token(role_id: "client_admin", client_id: client.symbol.downcase) }
      let(:headers) { { 'ACCEPT'=>'application/vnd.api+json', 'CONTENT_TYPE'=>'application/vnd.api+json', 'Authorization' => 'Bearer ' + bearer } }

      before { get "/dois/#{other_doi.doi}", headers: headers }

      it 'returns with landing page results' do
        expect(json.dig('data', 'attributes', 'doi')).to eq(other_doi.doi)
        expect(json.dig('data', 'attributes', 'landingPage')).to eq(nil)
      end
    end


    context 'authorised staff admin read' do
      let(:bearer) { User.generate_token(role_id: "client_admin", client_id: client.symbol.downcase) }
      let(:headers) { { 'ACCEPT'=>'application/vnd.api+json', 'CONTENT_TYPE'=>'application/vnd.api+json', 'Authorization' => 'Bearer ' + admin_bearer } }

      before { get "/dois/#{doi.doi}", headers: headers }

      it 'returns with landing page results' do
        expect(json.dig('data', 'attributes', 'doi')).to eq(doi.doi)
        expect(json.dig('data', 'attributes', 'landingPage')).to eq(landing_page)
      end
    end

  end

  describe 'GET /dois/random?prefix' do
    before { get "/dois/random?prefix=#{prefix.prefix}", headers: headers }

    it 'returns random doi with prefix' do
      expect(json['doi']).to start_with("10.14454")
      expect(response).to have_http_status(200)
    end

    it 'returns status code 200' do
      expect(response).to have_http_status(200)
    end
  end

  describe 'GET /dois/random?number' do
    let(:number) { 122149076 }
    before { get "/dois/random?number=#{number}", headers: headers }

    it 'returns predictable doi' do
      expect(json['doi']).to eq("10.5072/3mfp-6m52")
    end

    it 'returns status code 200' do
      expect(response).to have_http_status(200)
    end
  end

  describe 'POST /dois/status', vcr: true do
    let(:doi) { create(:doi, url: "https://blog.datacite.org/re3data-science-europe/") }

    before { post "/dois/status?id=#{doi.doi}", headers: headers }

    it 'returns landing page status' do
      expect(json['status']).to eq(200)
      expect(json['content-type']).to eq("text/html")
    end

    it 'returns status code 200' do
      expect(response).to have_http_status(200)
    end
  end

  describe 'POST /dois/status pdf', vcr: true do
    let(:doi) { create(:doi, url: "https://schema.datacite.org/meta/kernel-4.1/doc/DataCite-MetadataKernel_v4.1.pdf") }

    before { post "/dois/status?id=#{doi.doi}", headers: headers }

    it 'returns landing page status' do
      expect(json['status']).to eq(200)
      expect(json['content-type']).to eq("application/pdf")
    end

    it 'returns status code 200' do
      expect(response).to have_http_status(200)
    end
  end

  describe 'POST /dois/status no doi', vcr: true do
    let(:url) { "https://blog.datacite.org/re3data-science-europe/" }

    before { post "/dois/status?url=#{url}", headers: headers }

    it 'returns landing page status' do
      expect(json['status']).to eq(200)
      expect(json['content-type']).to eq("text/html")
    end

    it 'returns status code 200' do
      expect(response).to have_http_status(200)
    end
  end

  describe 'POST /dois/status no doi pdf', vcr: true do
    let(:url) { "https://schema.datacite.org/meta/kernel-4.1/doc/DataCite-MetadataKernel_v4.1.pdf" }

    before { post "/dois/status?url=#{url}", headers: headers }

    it 'returns landing page status' do
      expect(json['status']).to eq(200)
      expect(json['content-type']).to eq("application/pdf")
    end

    it 'returns status code 200' do
      expect(response).to have_http_status(200)
    end
  end

  describe 'GET /dois/DOI/get-url', vcr: true do
    let(:doi) { create(:doi, client: client, doi: "10.5438/fj3w-0shd", url: "https://blog.datacite.org/data-driven-development/", event: "publish") }

    before { get "/dois/#{doi.doi}/get-url", headers: headers }

    it 'returns url' do
      expect(json["url"]).to eq("https://blog.datacite.org/data-driven-development/")
    end

    it 'returns status code 200' do
      expect(response).to have_http_status(200)
    end
  end

  describe 'GET /dois/DOI/get-url no password', vcr: true do
    let(:doi) { create(:doi, client: client, doi: "10.14454/05mb-q396", event: "publish") }

    before { get "/dois/#{doi.doi}/get-url", headers: { 'ACCEPT'=>'application/vnd.api+json' } }

    it 'returns error' do
      expect(json['errors']).to eq([{"status"=>"401", "title"=>"Bad credentials."}])
    end

    it 'returns status code 401' do
      expect(response).to have_http_status(401)
    end
  end

  describe 'GET /dois/DOI/get-url wrong password', vcr: true do
    let(:doi) { create(:doi, client: client, doi: "10.14454/05mb-q396", event: "publish") }
    let(:credentials) { client.encode_auth_param(username: client.symbol.downcase, password: "12345") }

    before { get "/dois/#{doi.doi}/get-url", headers: { 'ACCEPT'=>'application/vnd.api+json', 'Authorization' => 'Basic ' + credentials } }

    it 'returns error' do
      expect(json['errors']).to eq([{"status"=>"401", "title"=>"Bad credentials."}])
    end

    it 'returns status code 401' do
      expect(response).to have_http_status(401)
    end
  end

  describe 'GET /dois/DOI/get-url no permission', vcr: true do
    let(:other_client) { create(:client, provider: provider) }
    let(:doi) { create(:doi, client: other_client, doi: "10.14454/8syz-ym47", event: "publish") }

    before { get "/dois/#{doi.doi}/get-url", headers: headers }

    it 'returns error' do
      expect(json['errors']).to eq([{"status"=>"403", "title"=>"You are not authorized to access this resource."}])
    end

    it 'returns status code 403' do
      expect(response).to have_http_status(403)
    end
  end

  describe 'GET /dois/DOI/get-url not found', vcr: true do
    let(:doi) { create(:doi, client: client, doi: "10.14454/61y1-e521", event: "publish") }

    before { get "/dois/#{doi.doi}/get-url", headers: headers }

    it 'returns not found' do
      expect(json['errors']).to eq([{"status"=>404, "title"=>"Not found"}])
    end

    it 'returns status code 404' do
      expect(response).to have_http_status(404)
    end
  end

  describe 'GET /dois/DOI/get-url draft doi', vcr: true do
    let(:doi) { create(:doi, client: client, doi: "10.14454/61y1-e521") }

    before { get "/dois/#{doi.doi}/get-url", headers: headers }

    it 'returns not found' do
      expect(json['url']).to eq(doi.url)
    end

    it 'returns status code 200' do
      expect(response).to have_http_status(200)
    end
  end

  describe 'GET /dois/DOI/get-url not DataCite DOI', vcr: true do
    let(:doi) { create(:doi, client: client, doi: "10.1371/journal.pbio.2001414", event: "publish") }

    before { get "/dois/#{doi.doi}/get-url", headers: headers }

    it 'returns nil' do
      expect(json['url']).to be_nil
    end

    it 'returns status code 200' do
      expect(response).to have_http_status(403)
    end
  end

  describe 'GET /dois/get-dois', vcr: true do
    let(:prefix) { create(:prefix, prefix: "10.5438") }
    let!(:client_prefix) { create(:client_prefix, prefix: prefix, client: client) }

    before { get "/dois/get-dois", headers: headers }

    it 'returns all dois' do
      expect(json["dois"].length).to eq(438)
      expect(json["dois"].first).to eq("10.5438/0000-00SS")
    end

    it 'returns status code 200' do
      expect(response).to have_http_status(200)
    end
  end

  describe 'GET /dois/get-dois no authentication', vcr: true do
    before { get "/dois/get-dois", headers: nil }

    it 'returns error message' do
      expect(json["errors"]).to eq([{"status"=>"401", "title"=>"Bad credentials."}])
    end

    it 'returns status code 401' do
      expect(response).to have_http_status(401)
    end
  end
end
