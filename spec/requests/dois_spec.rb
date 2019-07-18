require 'rails_helper'

describe "dois", type: :request do
  let(:admin) { create(:provider, symbol: "ADMIN") }
  let(:admin_bearer) { Client.generate_token(role_id: "staff_admin", uid: admin.symbol, password: admin.password) }
  let(:admin_headers) { { 'HTTP_ACCEPT'=>'application/vnd.api+json', 'HTTP_AUTHORIZATION' => 'Bearer ' + admin_bearer} }

  let(:provider) { create(:provider, symbol: "DATACITE") }
  let(:client) { create(:client, provider: provider, symbol: ENV['MDS_USERNAME'], password: ENV['MDS_PASSWORD']) }
  let!(:prefix) { create(:prefix, prefix: "10.14454") }
  let!(:client_prefix) { create(:client_prefix, client: client, prefix: prefix) }

  let(:doi) { create(:doi, client: client) }
  let(:bearer) { Client.generate_token(role_id: "client_admin", uid: client.symbol, provider_id: provider.symbol.downcase, client_id: client.symbol.downcase, password: client.password) }
  let(:headers) { { 'HTTP_ACCEPT'=>'application/vnd.api+json', 'HTTP_AUTHORIZATION' => 'Bearer ' + bearer }}

  describe 'GET /dois', elasticsearch: true do
    let!(:dois) { create_list(:doi, 3, client: client, aasm_state: "findable") }

    before do
      Doi.import
      sleep 1
    end

    it 'returns dois' do
      get '/dois', nil, headers

      expect(last_response.status).to eq(200)
      expect(json['data'].size).to eq(3)
      expect(json.dig('meta', 'total')).to eq(3)
    end

    it 'returns dois with extra detail' do
      get '/dois?detail=true', nil, headers

      expect(last_response.status).to eq(200)
      expect(json['data'].size).to eq(3)
      json['data'].each do |doi|
        expect(doi.dig('attributes')).to include('xml')
      end
    end
  end

  describe 'GET /dois/:id', elasticsearch: true do
    let!(:doi) { create(:doi, client: client) }

    before do
      Doi.import
      sleep 1
    end

    context 'when the record exists' do
      it 'returns the Doi' do
        get "/dois/#{doi.doi}", nil, headers

        expect(last_response.status).to eq(200)
        expect(json.dig('data', 'attributes', 'doi')).to eq(doi.doi.downcase)
      end
    end

    context 'when the record does not exist' do
      it 'returns status code 404' do
        get "/dois/10.5256/xxxx", nil, headers

        expect(last_response.status).to eq(404)
        expect(json).to eq("errors"=>[{"status"=>"404", "title"=>"The resource you are looking for doesn't exist."}])
      end
    end

    context 'anonymous user' do
      it 'returns the Doi' do
        get "/dois/#{doi.doi}"

        expect(last_response.status).to eq(401)
        expect(json.fetch('errors')).to eq([{"status"=>"401", "title"=>"Bad credentials."}])
      end
    end

    context 'invalid password' do
      let(:bearer) { Client.generate_token(role_id: "client_admin", uid: client.symbol, provider_id: provider.symbol.downcase, client_id: client.symbol.downcase, password: "abc") }
      let(:headers) { { 'HTTP_ACCEPT'=>'application/vnd.api+json', 'HTTP_AUTHORIZATION' => 'Bearer ' + bearer }}

      it 'returns the Doi' do
        get "/dois/#{doi.doi}"

        expect(last_response.status).to eq(401)
        expect(json.fetch('errors')).to eq([{"status"=>"401", "title"=>"Bad credentials."}])
      end
    end

    context 'creators started as an object not array' do
      let(:doi) { create(:doi, client: client, creators:
        {
          "nameType" => "Personal",
          "name" => "John Doe"
        })
      }

      it 'returns the creators as list' do
        get "/dois/#{doi.doi}", nil, headers

        expect(last_response.status).to eq(200)
        expect(json.dig('data', 'attributes', 'creators')).to eq([doi.creators])
      end
    end
  end

  describe 'state' do
    let(:doi_id) { "10.14454/4K3M-NYVG" }
    let(:xml) { Base64.strict_encode64(file_fixture('datacite.xml').read) }
    let(:bearer) { User.generate_token(role_id: "client_admin", client_id: client.symbol.downcase) }
    let(:headers) { {'HTTP_ACCEPT'=>'application/vnd.api+json', 'HTTP_AUTHORIZATION' => 'Bearer ' + bearer}}

    context 'initial state draft', elasticsearch: true do
      let!(:doi) { create(:doi, client: client) }

      before do
        Doi.import
        sleep 1
      end

      it 'fetches the record' do
        get "/dois/#{doi.doi}", nil, headers

        expect(last_response.status).to eq(200)
        expect(json.dig('data', 'attributes', 'url')).to eq(doi.url)
        expect(json.dig('data', 'attributes', 'doi')).to eq(doi.doi.downcase)
        expect(json.dig('data', 'attributes', 'titles')).to eq(doi.titles)
        expect(json.dig('data', 'attributes', 'isActive')).to be false
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

      it 'creates the record' do
        patch "/dois/#{doi_id}", valid_attributes, headers

        expect(last_response.status).to eq(201)
        expect(json.dig('data', 'attributes', 'doi')).to eq(doi_id.downcase)
        expect(json.dig('data', 'attributes', 'url')).to eq("http://www.bl.uk/pdf/pat.pdf")
        expect(json.dig('data', 'attributes', 'isActive')).to be false
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

      it 'creates the record' do
        patch "/dois/#{doi_id}", valid_attributes, headers

        expect(last_response.status).to eq(422)
        expect(json["errors"]).to eq([{"source"=>"url", "title"=>"Can't be blank"}])
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

      it 'updates the record' do
        patch "/dois/#{doi_id}", valid_attributes, headers

        expect(last_response.status).to eq(201)
        expect(json.dig('data', 'attributes', 'doi')).to eq(doi_id.downcase)
        expect(json.dig('data', 'attributes', 'url')).to eq("http://www.bl.uk/pdf/pat.pdf")
        expect(json.dig('data', 'attributes', 'isActive')).to be true
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

      it 'updates the record' do
        patch "/dois/#{doi_id}", valid_attributes, headers

        expect(last_response.status).to eq(422)
        expect(json["errors"]).to eq([{"source"=>"url", "title"=>"Can't be blank"}])
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

      it 'updates the record' do
        patch "/dois/#{doi.doi}", valid_attributes, headers

        expect(last_response.status).to eq(200)
        expect(json.dig('data', 'attributes', 'doi')).to eq(doi.doi.downcase)
        expect(json.dig('data', 'attributes', 'isActive')).to be false
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

      it 'updates the record' do
        patch "/dois/#{doi.doi}", valid_attributes, headers

        expect(last_response.status).to eq(200)
        expect(json.dig('data', 'attributes', 'doi')).to eq(doi.doi.downcase)
        expect(json.dig('data', 'attributes', 'isActive')).to be false
        expect(json.dig('data', 'attributes', 'reason')).to eq("withdrawn by author")
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

      it 'updates the record' do
        patch "/dois/#{doi.doi}", valid_attributes, headers

        expect(last_response.status).to eq(200)
        expect(json.dig('data', 'attributes', 'url')).to eq("http://www.bl.uk/pdf/pat.pdf")
        expect(json.dig('data', 'attributes', 'doi')).to eq(doi.doi.downcase)
        expect(json.dig('data', 'attributes', 'titles')).to eq([{"title"=>"Eating your own Dog Food"}])
      end

      it 'sets state to draft' do
        patch "/dois/#{doi.doi}", valid_attributes, headers

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

      it 'raises an error' do
        patch "/dois/#{doi.doi}", valid_attributes, headers

        expect(last_response.status).to eq(400)
        expect(json.dig('errors')).to eq([{"status"=>"400", "title"=>"You need to provide a payload following the JSONAPI spec"}])
      end
    end

    context 'update sizes' do
      let(:doi) { create(:doi, doi: "10.14454/10703", client: client) }
      let(:sizes) { ["100 samples", "56 pages"] }
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "sizes" => sizes,
              "event" => "publish"
            }
          }
        }
      end

      it 'updates the doi' do
        put "/dois/#{doi.doi}", valid_attributes, admin_headers

        expect(last_response.status).to eq(200)
        expect(json.dig('data', 'attributes', 'sizes')).to eq(sizes)
      end
    end

    context 'update formats' do
      let(:doi) { create(:doi, doi: "10.14454/10703", client: client) }
      let(:formats) { ["application/json"] }
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "formats" => formats,
              "event" => "publish"
            }
          }
        }
      end

      it 'updates the doi' do
        put "/dois/#{doi.doi}", valid_attributes, admin_headers

        expect(last_response.status).to eq(200)
        expect(json.dig('data', 'attributes', 'formats')).to eq(formats)
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

      it 'returns error' do
        put "/dois/#{doi.doi}", valid_attributes, headers

        expect(last_response.status).to eq(422)
        expect(json["errors"]).to eq([{"source"=>"creators", "title"=>"Missing child element(s). expected is ( {http://datacite.org/schema/kernel-4}creator ). at line 4, column 0"}])
      end
    end

    context 'when the record exists https://github.com/datacite/lupo/issues/89' do
      let(:doi) { create(:doi, doi: "10.14454/119496", client: client) }
      let(:valid_attributes) { JSON.parse(file_fixture('datacite_89.json').read) }

      it 'returns no errors' do
        put "/dois/#{doi.doi}", valid_attributes, headers

        expect(last_response.status).to eq(200)
        expect(json.dig('data', 'attributes', 'doi')).to eq(doi.doi)
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

      it 'returns status code 422' do
        patch "/dois/10.14454/10703", valid_attributes, headers

        expect(last_response.status).to eq(422)
        expect(json.fetch('errors', nil)).to eq([{"source"=>"xml", "title"=>"Schema http://datacite.org/schema/kernel-2.2 is no longer supported"}])
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

      it 'returns no errors' do
        put "/dois/#{doi.doi}", valid_attributes, headers

        expect(last_response.status).to eq(200)
        expect(json.dig('data', 'attributes', 'doi')).to eq(doi.doi.downcase)
        expect(json.dig('data', 'attributes', 'url')).to eq(url)
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

      it 'creates the record' do
        put "/dois/#{doi_id}", valid_attributes, headers

        expect(last_response.status).to eq(201)
        expect(json.dig('data', 'attributes', 'url')).to eq("http://www.bl.uk/pdf/pat.pdf")
        expect(json.dig('data', 'attributes', 'doi')).to eq(doi_id.downcase)
        expect(json.dig('data', 'attributes', 'titles')).to eq([{"title"=>"Eating your own Dog Food"}])
      end

      it 'sets state to findable' do
        put "/dois/#{doi_id}", valid_attributes, headers

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

      it 'returns error' do
        put "/dois/#{doi_id}", valid_attributes, headers

        expect(last_response.status).to eq(422)
        expect(json["errors"]).to eq([{"source"=>"creators", "title"=>"Missing child element(s). expected is ( {http://datacite.org/schema/kernel-4}creator ). at line 4, column 0"}])
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

      it 'updates the record' do
        patch "/dois/#{doi.doi}", valid_attributes, headers

        expect(last_response.status).to eq(200)
        expect(json.dig('data', 'attributes', 'url')).to eq("http://www.bl.uk/pdf/pat.pdf")
        expect(json.dig('data', 'attributes', 'doi')).to eq(doi.doi.downcase)
        expect(json.dig('data', 'attributes', 'titles')).to eq([{"title"=>"Automated quantitative histology reveals vascular morphodynamics during Arabidopsis hypocotyl secondary growth"}])
      end

      it 'sets state to registered' do
        patch "/dois/#{doi.doi}", valid_attributes, headers

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

      it 'updates the record' do
        patch "/dois/#{doi.doi}", valid_attributes, headers

        expect(last_response.status).to eq(200)
        expect(json.dig('data', 'attributes', 'url')).to eq("http://www.bl.uk/pdf/pat.pdf")
        expect(json.dig('data', 'attributes', 'doi')).to eq(doi.doi.downcase)
        expect(json.dig('data', 'attributes', 'titles')).to eq(titles)
      end

      it 'sets state to findable' do
        patch "/dois/#{doi.doi}", valid_attributes, headers

        expect(json.dig('data', 'attributes', 'state')).to eq("findable")
      end
    end

    context 'when a doi is created ignore reverting back' do
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
      let(:undo_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "doi" => doi.doi
            }
          }
        }
      end

      it 'creates the record' do
        post '/dois', valid_attributes, headers

        expect(last_response.status).to eq(201)
        expect(json.dig('data', 'attributes', 'titles')).to eq([{"title"=>"Eating your own Dog Food"}])
      end

      it 'revert the changes' do
        post '/dois', valid_attributes, headers

        expect(last_response.status).to eq(201)
        post "/dois/undo", undo_attributes, headers

        expect(last_response.status).to eq(200)
        expect(json.dig('data', 'attributes', 'titles')).to eq([{"title"=>"Data from: A new malaria agent in African hominids."}])
      end
    end

    context 'when the title is changed and reverted back' do
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
      let(:undo_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "doi" => doi.doi
            }
          }
        }
      end

      it 'updates the record' do
        patch "/dois/#{doi.doi}", valid_attributes, headers

        expect(last_response.status).to eq(200)
        expect(json.dig('data', 'attributes', 'titles')).to eq(titles)
      end

      it 'revert the changes' do
        patch "/dois/#{doi.doi}", valid_attributes, headers

        expect(last_response.status).to eq(200)
        post "/dois/undo", undo_attributes, headers

        expect(last_response.status).to eq(200)
        expect(json.dig('data', 'attributes', 'titles')).to eq([{"title"=>"Data from: A new malaria agent in African hominids."}])
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

      it 'updates the record' do
        patch "/dois/#{doi.doi}", valid_attributes, headers

        expect(last_response.status).to eq(200)
        expect(json.dig('data', 'attributes', 'url')).to eq("http://www.bl.uk/pdf/pat.pdf")
        expect(json.dig('data', 'attributes', 'doi')).to eq(doi.doi.downcase)
        expect(json.dig('data', 'attributes', 'creators')).to eq(creators)
      end

      it 'sets state to findable' do
        patch "/dois/#{doi.doi}", valid_attributes, headers

        expect(json.dig('data', 'attributes', 'state')).to eq("findable")
      end
    end

    context 'fail when we transfer a DOI as provider' do
      let(:provider_bearer) { User.generate_token(uid: "datacite", role_id: "provider_admin", name: "DataCite", email:"support@datacite.org", provider_id: "datacite") }
      let(:provider_headers) { {'HTTP_ACCEPT'=>'application/vnd.api+json', 'CONTENT_TYPE'=>'application/vnd.api+json', 'HTTP_AUTHORIZATION' => 'Bearer ' + provider_bearer}}

      let(:doi) { create(:doi, client: client) }
      let(:new_client) { create(:client, symbol: "#{provider.symbol}.magic", provider: provider, password: ENV['MDS_PASSWORD']) }

      # attributes MUST be empty
      let(:valid_attributes) { file_fixture('transfer.json').read }

      it 'returns errors' do
        put "/dois/#{doi.doi}", valid_attributes.to_json, provider_headers

        expect(last_response.status).to eq(403)
      end
    end

    context 'passes when we transfer a DOI as provider' do
      let(:provider_bearer) { User.generate_token(uid: "datacite", role_id: "provider_admin", name: "DataCite", email:"support@datacite.org", provider_id: "datacite") }
      let(:provider_headers) { {'HTTP_ACCEPT'=>'application/vnd.api+json', 'CONTENT_TYPE'=>'application/vnd.api+json', 'HTTP_AUTHORIZATION' => 'Bearer ' + provider_bearer}}

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

      it 'updates the client id' do
        put "/dois/#{doi.doi}", valid_attributes.to_json, provider_headers

        expect(last_response.status).to eq(200)
        expect(json.dig('data', 'attributes', 'doi')).to eq(doi.doi.downcase)
        expect(json.dig('data', 'relationships', 'client','data','id')).to eq(new_client.symbol.downcase)
        expect(json.dig('data', 'attributes', 'titles')).to eq(doi.titles)
      end
    end

    context 'when we transfer a DOI as staff' do
      let(:doi) { create(:doi, doi: "10.14454/119495", url: "http://www.bl.uk/pdf/pat.pdf", client: client, aasm_state: "registered") }
      let(:new_client) { create(:client, symbol: "#{provider.symbol}.magic", provider: provider, password: ENV['MDS_PASSWORD']) }
      let(:xml) { Base64.strict_encode64(file_fixture('datacite.xml').read) }
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "mode" => "transfer"
            },
            "relationships" => {
              "client" =>  {
                "data" => {
                  "type" => "clients",
                  "id" => new_client.symbol.downcase
                }
              }
            }
          }
        }
      end

      it 'updates the client id' do
        put "/dois/#{doi.doi}", valid_attributes, admin_headers

        expect(last_response.status).to eq(200)
        expect(json.dig('data', 'attributes', 'doi')).to eq(doi.doi)
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

      it 'updates the record' do
        patch "/dois/#{doi.doi}", valid_attributes, headers

        expect(last_response.status).to eq(200)
        expect(json.dig('data', 'attributes', 'url')).to eq("http://www.bl.uk/pdf/pat.pdf")
        expect(json.dig('data', 'attributes', 'doi')).to eq(doi.doi.downcase)
        expect(json.dig('data', 'attributes', 'types')).to eq("resourceType"=>"BlogPosting", "resourceTypeGeneral"=>"DataPaper")
      end

      it 'sets state to findable' do
        patch "/dois/#{doi.doi}", valid_attributes, headers

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

      it 'creates a Doi' do
        post '/dois', valid_attributes, headers

        expect(last_response.status).to eq(201)
        expect(json.dig('data', 'attributes', 'url')).to eq("http://www.bl.uk/pdf/patspec.pdf")
        expect(json.dig('data', 'attributes', 'doi')).to eq("10.14454/10703")
        expect(json.dig('data', 'attributes', 'titles')).to eq([{"title"=>"Eating your own Dog Food"}])
        expect(json.dig('data', 'attributes', 'creators')).to eq([{"familyName"=>"Fenner",
          "givenName"=>"Martin",
          "name"=>"Fenner, Martin",
          "nameIdentifiers"=>
            [{"nameIdentifier"=>"https://orcid.org/0000-0003-1419-2405",
              "nameIdentifierScheme"=>"ORCID",
              "schemeUri"=>"https://orcid.org"}],
          "nameType"=>"Personal"}])
        expect(json.dig('data', 'attributes', 'schemaVersion')).to eq("http://datacite.org/schema/kernel-4")
        expect(json.dig('data', 'attributes', 'source')).to eq("test")
        expect(json.dig('data', 'attributes', 'types')).to eq("bibtex"=>"article", "citeproc"=>"article-journal", "resourceType"=>"BlogPosting", "resourceTypeGeneral"=>"Text", "ris"=>"RPRT", "schemaOrg"=>"ScholarlyArticle")
        expect(json.dig('data', 'attributes', 'state')).to eq("findable")

        doc = Nokogiri::XML(Base64.decode64(json.dig('data', 'attributes', 'xml')), nil, 'UTF-8', &:noblanks)
        expect(doc.at_css("identifier").content).to eq("10.14454/10703")
      end
    end

    context 'when the request is valid random doi' do
      let(:xml) { Base64.strict_encode64(file_fixture('datacite.xml').read) }
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "prefix" => "10.14454",
              "url" => "http://www.bl.uk/pdf/patspec.pdf",
              "xml" => xml,
              "source" => "test",
              "event" => "publish"
            }
          }
        }
      end

      it 'creates a Doi' do
        post '/dois', valid_attributes, headers

        expect(last_response.status).to eq(201)
        expect(json.dig('data', 'attributes', 'url')).to eq("http://www.bl.uk/pdf/patspec.pdf")
        expect(json.dig('data', 'attributes', 'doi')).to start_with("10.14454")
        expect(json.dig('data', 'attributes', 'titles')).to eq([{"title"=>"Eating your own Dog Food"}])
        expect(json.dig('data', 'attributes', 'creators')).to eq([{"familyName"=>"Fenner",
          "givenName"=>"Martin",
          "name"=>"Fenner, Martin",
          "nameIdentifiers"=>
            [{"nameIdentifier"=>"https://orcid.org/0000-0003-1419-2405",
              "nameIdentifierScheme"=>"ORCID",
              "schemeUri"=>"https://orcid.org"}],
          "nameType"=>"Personal"}])
        expect(json.dig('data', 'attributes', 'schemaVersion')).to eq("http://datacite.org/schema/kernel-4")
        expect(json.dig('data', 'attributes', 'source')).to eq("test")
        expect(json.dig('data', 'attributes', 'types')).to eq("bibtex"=>"article", "citeproc"=>"article-journal", "resourceType"=>"BlogPosting", "resourceTypeGeneral"=>"Text", "ris"=>"RPRT", "schemaOrg"=>"ScholarlyArticle")
        expect(json.dig('data', 'attributes', 'state')).to eq("findable")

        doc = Nokogiri::XML(Base64.decode64(json.dig('data', 'attributes', 'xml')), nil, 'UTF-8', &:noblanks)
        expect(doc.at_css("identifier").content).to start_with("10.14454")
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
              "creators" => [{"familyName"=>"Fenner", "givenName"=>"Martin", "nameIdentifiers"=>[{ "nameIdentifier" => "https://orcid.org/0000-0003-1419-2405", "nameIdentifierScheme" => "ORCID", "schemeUri"=>"https://orcid.org" }], "name"=>"Fenner, Martin", "nameType"=>"Personal"}],
              "source" => "test",
              "event" => "publish"
            }
          }
        }
      end

      it 'creates a Doi' do
        post '/dois', valid_attributes, headers

        expect(last_response.status).to eq(201)
        expect(json.dig('data', 'attributes', 'url')).to eq("http://www.bl.uk/pdf/patspec.pdf")
        expect(json.dig('data', 'attributes', 'doi')).to eq("10.14454/10703")
        expect(json.dig('data', 'attributes', 'titles')).to eq([{"title"=>"Eating your own Dog Food"}])
        expect(json.dig('data', 'attributes', 'creators')).to eq([{"familyName"=>"Fenner", "givenName"=>"Martin", "nameIdentifiers"=>[{"nameIdentifier"=>"https://orcid.org/0000-0003-1419-2405","nameIdentifierScheme"=>"ORCID", "schemeUri"=>"https://orcid.org"}], "name"=>"Fenner, Martin", "nameType"=>"Personal"}])
        expect(json.dig('data', 'attributes', 'publisher')).to eq("DataCite")
        expect(json.dig('data', 'attributes', 'publicationYear')).to eq(2016)
        # expect(json.dig('data', 'attributes', 'schemaVersion')).to eq("http://datacite.org/schema/kernel-4")
        expect(json.dig('data', 'attributes', 'source')).to eq("test")
        expect(json.dig('data', 'attributes', 'types')).to eq("bibtex"=>"article", "citeproc"=>"article-journal", "resourceType"=>"BlogPosting", "resourceTypeGeneral"=>"Text", "ris"=>"RPRT", "schemaOrg"=>"ScholarlyArticle")
        expect(json.dig('data', 'attributes', 'state')).to eq("findable")

        doc = Nokogiri::XML(Base64.decode64(json.dig('data', 'attributes', 'xml')), nil, 'UTF-8', &:noblanks)
        expect(doc.at_css("identifier").content).to eq("10.14454/10703")
      end
    end

    context 'with affiliation' do
      let(:xml) { ::Base64.strict_encode64(File.read(file_fixture('datacite-example-affiliation.xml'))) }
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

      it 'validates a Doi' do
        post '/dois', params, headers

        expect(last_response.status).to eq(201)
        expect(json.dig('data', 'attributes', 'titles')).to eq([{"lang"=>"en-US", "title"=>"Full DataCite XML Example"}, {"lang"=>"en-US", "title"=>"Demonstration of DataCite Properties.", "titleType"=>"Subtitle"}])
        expect(json.dig('data', 'attributes', 'creators').length).to eq(3)
        expect(json.dig('data', 'attributes', 'creators')[0]).to eq("affiliation" => [{"affiliationIdentifierScheme"=>"ROR", "affiliationIdentifier"=>"https://ror.org/04wxnsj81", "name"=>"DataCite"}],
          "familyName" => "Miller",
          "givenName" => "Elizabeth",
          "name" => "Miller, Elizabeth",
          "nameIdentifiers" => [{"nameIdentifier"=>"https://orcid.org/0000-0001-5000-0007", "nameIdentifierScheme"=>"ORCID", "schemeUri"=>"https://orcid.org"}],
          "nameType" => "Personal")
        expect(json.dig('data', 'attributes', 'creators')[1]).to eq("affiliation" => [{"affiliationIdentifierScheme"=>"ROR", "affiliationIdentifier"=>"https://ror.org/05gq02987", "name"=>"Brown University"}, {"affiliationIdentifierScheme"=>"GRID", "affiliationIdentifier"=>"https://grid.ac/institutes/grid.268117.b", "name"=>"Wesleyan University"}],
          "familyName" => "Carberry",
          "givenName" => "Josiah",
          "name" => "Carberry, Josiah",
          "nameIdentifiers" => [{"nameIdentifier"=>"https://orcid.org/0000-0002-1825-0097", "nameIdentifierScheme"=>"ORCID", "schemeUri"=>"https://orcid.org"}],
          "nameType" => "Personal")
        expect(json.dig('data', 'attributes', 'creators')[2]).to eq("nameType"=>"Organizational", "name"=>"The Psychoceramics Study Group", "affiliation"=>[{"affiliationIdentifier"=>"https://ror.org/05gq02987", "name"=>"Brown University", "affiliationIdentifierScheme"=>"ROR"}])

        xml = Maremma.from_xml(Base64.decode64(json.dig('data', 'attributes', 'xml'))).fetch("resource", {})
        expect(xml.dig("creators", "creator")[0]).to eq("affiliation" => {"__content__"=>"DataCite", "affiliationIdentifier"=>"https://ror.org/04wxnsj81", "affiliationIdentifierScheme"=>"ROR"},
          "creatorName" => {"__content__"=>"Miller, Elizabeth", "nameType"=>"Personal"},
          "familyName" => "Miller",
          "givenName" => "Elizabeth",
          "nameIdentifier" => {"__content__"=>"0000-0001-5000-0007", "nameIdentifierScheme"=>"ORCID", "schemeURI"=>"http://orcid.org/"})
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

      it 'updates the record' do
        patch "/dois/10.14454/8na3-9s47", valid_attributes, headers

        expect(last_response.status).to eq(201)
        expect(json.dig('data', 'attributes', 'url')).to eq("https://ors.datacite.org/doi:/10.14454/8na3-9s47")
        expect(json.dig('data', 'attributes', 'doi')).to eq("10.14454/8na3-9s47")
        expect(json.dig('data', 'attributes', 'contentUrl')).to eq(["s3://cgp-commons-public/topmed_open_access/197bc047-e917-55ed-852d-d563cdbc50e4/NWD165827.recab.cram", "gs://topmed-irc-share/public/NWD165827.recab.cram"])
        expect(json.dig('data', 'attributes', 'titles')).to eq([{"title"=>"NWD165827.recab.cram"}])
        expect(json.dig('data', 'attributes', 'state')).to eq("findable")

        xml = Maremma.from_xml(Base64.decode64(json.dig('data', 'attributes', 'xml'))).fetch("resource", {})
        expect(xml.dig("titles", "title")).to eq("NWD165827.recab.cram")
      end
    end

    context 'crossref url', vcr: true do
      let(:provider) { create(:provider, name: "Crossref", symbol: "CROSSREF", role_name: "ROLE_REGISTRATION_AGENCY") }
      let(:client) { create(:client, provider: provider, name: "Crossref Citations", symbol: "CROSSREF.CITATIONS") }

      let(:xml) { Base64.strict_encode64("https://doi.org/10.7554/elife.01567") }
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "xml" => xml,
              "source" => "test",
              "event" => "publish"
            },
            "relationships" => {
              "client" =>  {
                "data" => {
                  "type" => "clients",
                  "id" => client.symbol.downcase
                }
              }
            }
          }
        }
      end

      it 'updates the record' do
        patch "/dois/10.7554/elife.01567", valid_attributes, headers

        expect(last_response.status).to eq(201)
        expect(json.dig('data', 'attributes', 'url')).to eq("https://elifesciences.org/articles/01567")
        expect(json.dig('data', 'attributes', 'doi')).to eq("10.7554/elife.01567")
        expect(json.dig('data', 'attributes', 'titles')).to eq([{"title"=>"Automated quantitative histology reveals vascular morphodynamics during Arabidopsis hypocotyl secondary growth"}])
        # expect(json.dig('data', 'attributes', 'agency')).to eq("Crossref")
        expect(json.dig('data', 'attributes', 'state')).to eq("findable")

        xml = Maremma.from_xml(Base64.decode64(json.dig('data', 'attributes', 'xml'))).fetch("resource", {})
        expect(xml.dig("titles", "title")).to eq("Automated quantitative histology reveals vascular morphodynamics during Arabidopsis hypocotyl secondary growth")
      end
    end

    context 'crossref url not found', vcr: true do
      let(:provider) { create(:provider, name: "Crossref", symbol: "CROSSREF", role_name: "ROLE_REGISTRATION_AGENCY") }
      let(:client) { create(:client, provider: provider, name: "Crossref Citations", symbol: "CROSSREF.CITATIONS") }

      let(:xml) { Base64.strict_encode64("https://doi.org/10.3389/fmicb.2019.01425") }
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "xml" => xml,
              "source" => "test",
              "event" => "publish"
            },
            "relationships" => {
              "client" =>  {
                "data" => {
                  "type" => "clients",
                  "id" => client.symbol.downcase
                }
              }
            }
          }
        }
      end

      it 'not found on updating the record' do
        patch "/dois/10.3389/fmicb.2019.01425", valid_attributes, headers

        expect(last_response.status).to eq(404)
        expect(json['errors']).to eq([{"status"=>"404", "title"=>"The resource you are looking for doesn't exist."}])
      end
    end

    context 'medra url', vcr: true do
      let(:provider) { create(:provider, name: "mEDRA", symbol: "MEDRA", role_name: "ROLE_REGISTRATION_AGENCY") }
      let(:client) { create(:client, provider: provider, name: "mEDRA Citations", symbol: "MEDRA.CITATIONS") }

      let(:xml) { Base64.strict_encode64("https://doi.org/10.3280/ecag2018-001005") }
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "xml" => xml,
              "source" => "test",
              "event" => "publish"
            },
            "relationships" => {
              "client" =>  {
                "data" => {
                  "type" => "clients",
                  "id" => client.symbol.downcase
                }
              }
            }
          }
        }
      end

      it 'updates the record' do
        patch "/dois/10.3280/ecag2018-001005", valid_attributes, headers

        expect(last_response.status).to eq(201)
        expect(json.dig('data', 'attributes', 'url')).to eq("http://www.francoangeli.it/riviste/Scheda_Riviste.asp?IDArticolo=61645")
        expect(json.dig('data', 'attributes', 'doi')).to eq("10.3280/ecag2018-001005")
        expect(json.dig('data', 'attributes', 'titles')).to eq([{"title"=>"Substitutability between organic and conventional poultry products and organic price premiums"}])
        # expect(json.dig('data', 'attributes', 'agency')).to eq("mEDRA")
        expect(json.dig('data', 'attributes', 'state')).to eq("findable")

        xml = Maremma.from_xml(Base64.decode64(json.dig('data', 'attributes', 'xml'))).fetch("resource", {})
        expect(xml.dig("titles", "title")).to eq("Substitutability between organic and conventional poultry products and organic price premiums")
      end
    end

    context 'kisti url', vcr: true do
      let(:provider) { create(:provider, name: "KISTI", symbol: "KISTI", role_name: "ROLE_REGISTRATION_AGENCY") }
      let(:client) { create(:client, provider: provider, name: "KISTI Citations", symbol: "KISTI.CITATIONS") }

      let(:xml) { Base64.strict_encode64("https://doi.org/10.5012/bkcs.2013.34.10.2889") }
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "xml" => xml,
              "source" => "test",
              "event" => "publish"
            },
            "relationships" => {
              "client" =>  {
                "data" => {
                  "type" => "clients",
                  "id" => client.symbol.downcase
                }
              }
            }
          }
        }
      end

      it 'updates the record' do
        patch "/dois/10.5012/bkcs.2013.34.10.2889", valid_attributes, headers

        expect(last_response.status).to eq(201)
        expect(json.dig('data', 'attributes', 'url')).to eq("http://koreascience.or.kr/journal/view.jsp?kj=JCGMCS&py=2013&vnc=v34n10&sp=2889")
        expect(json.dig('data', 'attributes', 'doi')).to eq("10.5012/bkcs.2013.34.10.2889")
        expect(json.dig('data', 'attributes', 'titles')).to eq([{"title"=>"Synthesis, Crystal Structure and Theoretical Calculation of a Novel Nickel(II) Complex with Dibromotyrosine and 1,10-Phenanthroline"}])
        # expect(json.dig('data', 'attributes', 'agency')).to eq("mEDRA")
        expect(json.dig('data', 'attributes', 'state')).to eq("findable")

        xml = Maremma.from_xml(Base64.decode64(json.dig('data', 'attributes', 'xml'))).fetch("resource", {})
        expect(xml.dig("titles", "title")).to eq("Synthesis, Crystal Structure and Theoretical Calculation of a Novel Nickel(II) Complex with Dibromotyrosine and 1,10-Phenanthroline")
      end
    end

    context 'jalc url', vcr: true do
      let(:provider) { create(:provider, name: "JaLC", symbol: "JALC", role_name: "ROLE_REGISTRATION_AGENCY") }
      let(:client) { create(:client, provider: provider, name: "JALC Citations", symbol: "JALC.CITATIONS") }

      let(:xml) { Base64.strict_encode64("https://doi.org/10.1241/johokanri.39.979") }
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "xml" => xml,
              "source" => "test",
              "event" => "publish"
            },
            "relationships" => {
              "client" =>  {
                "data" => {
                  "type" => "clients",
                  "id" => client.symbol.downcase
                }
              }
            }
          }
        }
      end

      it 'updates the record' do
        patch "/dois/10.1241/johokanri.39.979", valid_attributes, headers

        expect(last_response.status).to eq(201)
        expect(json.dig('data', 'attributes', 'url')).to eq("http://joi.jlc.jst.go.jp/JST.JSTAGE/johokanri/39.979?from=CrossRef")
        expect(json.dig('data', 'attributes', 'doi')).to eq("10.1241/johokanri.39.979")
        expect(json.dig('data', 'attributes', 'titles')).to eq([{"title"=>"Utilizing the Internet. 12 Series. Future of the Internet."}])
        # expect(json.dig('data', 'attributes', 'agency')).to eq("mEDRA")
        expect(json.dig('data', 'attributes', 'state')).to eq("findable")

        xml = Maremma.from_xml(Base64.decode64(json.dig('data', 'attributes', 'xml'))).fetch("resource", {})
        expect(xml.dig("titles", "title")).to eq("Utilizing the Internet. 12 Series. Future of the Internet.")
      end
    end

    context 'op url', vcr: true do
      let(:provider) { create(:provider, name: "OP", symbol: "OP", role_name: "ROLE_REGISTRATION_AGENCY") }
      let(:client) { create(:client, provider: provider, name: "OP Citations", symbol: "OP.CITATIONS") }

      let(:xml) { Base64.strict_encode64("https://doi.org/10.2903/j.efsa.2018.5239") }
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "xml" => xml,
              "source" => "test",
              "event" => "publish"
            },
            "relationships" => {
              "client" =>  {
                "data" => {
                  "type" => "clients",
                  "id" => client.symbol.downcase
                }
              }
            }
          }
        }
      end

      it 'updates the record' do
        patch "/dois/10.2903/j.efsa.2018.5239", valid_attributes, headers

        expect(last_response.status).to eq(201)
        expect(json.dig('data', 'attributes', 'url')).to eq("http://doi.wiley.com/10.2903/j.efsa.2018.5239")
        expect(json.dig('data', 'attributes', 'doi')).to eq("10.2903/j.efsa.2018.5239")
        expect(json.dig('data', 'attributes', 'titles')).to eq([{"title"=>"Scientific opinion on the safety of green tea catechins"}])
        # expect(json.dig('data', 'attributes', 'agency')).to eq("mEDRA")
        expect(json.dig('data', 'attributes', 'state')).to eq("findable")

        xml = Maremma.from_xml(Base64.decode64(json.dig('data', 'attributes', 'xml'))).fetch("resource", {})
        expect(xml.dig("titles", "title")).to eq("Scientific opinion on the safety of green tea catechins")
      end
    end

    context 'datacite url', vcr: true do
      let(:xml) { Base64.strict_encode64("https://doi.org/10.7272/q6g15xs4") }
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "url" => "https://datashare.ucsf.edu/stash/dataset/doi:10.7272/Q6G15XS4",
              "xml" => xml,
              "source" => "test",
              "event" => "publish"
            }
          }
        }
      end

      it 'updates the record' do
        patch "/dois/10.14454/q6g15xs4", valid_attributes, headers
        puts last_response.body
        expect(last_response.status).to eq(201)
        expect(json.dig('data', 'attributes', 'url')).to eq("https://datashare.ucsf.edu/stash/dataset/doi:10.7272/Q6G15XS4")
        expect(json.dig('data', 'attributes', 'doi')).to eq("10.14454/q6g15xs4")
        expect(json.dig('data', 'attributes', 'titles')).to eq([{"title"=>"NEXUS Head CT"}])
        expect(json.dig('data', 'attributes', 'state')).to eq("findable")

        xml = Maremma.from_xml(Base64.decode64(json.dig('data', 'attributes', 'xml'))).fetch("resource", {})
        expect(xml.dig("titles", "title")).to eq("NEXUS Head CT")
      end
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
            }
          }
        }
      end

      it 'creates a Doi' do
        post '/dois', valid_attributes, headers

        expect(last_response.status).to eq(201)
        expect(json.dig('data', 'attributes', 'url')).to eq("http://www.bl.uk/pdf/patspec.pdf")
        expect(json.dig('data', 'attributes', 'doi')).to eq("10.14454/10703")
        expect(json.dig('data', 'attributes', 'titles')).to eq([{"title"=>"Data from: A new malaria agent in African hominids."}])
        expect(json.dig('data', 'attributes', 'source')).to eq("test")
        expect(json.dig('data', 'attributes', 'schemaVersion')).to eq("http://datacite.org/schema/kernel-3")
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

      it 'returns an error that schema is no longer supported' do
        post '/dois', valid_attributes, headers

        expect(last_response.status).to eq(422)
        expect(json.fetch('errors', nil)).to eq([{"source"=>"xml", "title"=>"Schema http://datacite.org/schema/kernel-2.2 is no longer supported"}])
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

      it 'creates a Doi' do
        post '/dois', valid_attributes, headers

        expect(last_response.status).to eq(201)
        expect(json.dig('data', 'attributes', 'doi')).to eq("10.14454/10703")
        expect(json.dig('data', 'attributes', 'titles')).to eq([{"title"=>"Southern Sierra Critical Zone Observatory (SSCZO), Providence Creek meteorological data, soil moisture and temperature, snow depth and air temperature"}])
        expect(json.dig('data', 'attributes', 'schemaVersion')).to eq("http://datacite.org/schema/kernel-4")
        expect(json.dig('data', 'attributes', 'state')).to eq("findable")
      end
    end

    context 'when the request uses schema 4.2' do
      let(:xml) { Base64.strict_encode64(file_fixture('schema_4.2.xml').read) }
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

      it 'creates a Doi' do
        post '/dois', valid_attributes, headers

        expect(last_response.status).to eq(201)
        expect(json.dig('data', 'attributes', 'doi')).to eq("10.14454/10703")
        expect(json.dig('data', 'attributes', 'titles')).to eq([{"title"=>"Southern Sierra Critical Zone Observatory (SSCZO), Providence Creek meteorological data, soil moisture and temperature, snow depth and air temperature"}])
        expect(json.dig('data', 'attributes', 'schemaVersion')).to eq("http://datacite.org/schema/kernel-4")
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

      it 'returns an error that schema is no longer supported' do
        post '/dois', valid_attributes, headers

        expect(last_response.status).to eq(422)
        expect(json.fetch('errors', nil)).to eq([{"source"=>"xml", "title"=>"Schema http://datacite.org/schema/kernel-2.2 is no longer supported"}])
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

      it 'creates a Doi' do
        post '/dois', valid_attributes, headers

        expect(last_response.status).to eq(201)
        expect(json.dig('data', 'attributes', 'doi')).to eq("10.14454/10703")
        expect(json.dig('data', 'attributes', 'titles')).to eq("title"=>"Referee report. For: RESEARCH-3482 [version 5; referees: 1 approved, 1 approved with reservations]")
        expect(json.dig('data', 'attributes', 'url')).to eq("http://www.bl.uk/pdf/patspec.pdf")
        expect(json.dig('data', 'attributes', 'source')).to eq("test")
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

      it 'creates a Doi' do
        post '/dois', valid_attributes, headers

        expect(last_response.status).to eq(201)
        expect(json.dig('data', 'attributes', 'doi')).to eq("10.14454/10703")
        expect(json.dig('data', 'attributes', 'url')).to eq(url)
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

      it 'creates a Doi' do
        post '/dois', valid_attributes, headers

        expect(last_response.status).to eq(201)
        expect(json.dig('data', 'attributes', 'doi')).to eq("10.14454/10703")
        expect(json.dig('data', 'attributes', 'titles')).to eq([{"title"=>"Eating your own Dog Food"}])
        expect(json.dig('data', 'attributes', 'url')).to eq("http://www.bl.uk/pdf/patspec.pdf")
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

      it 'creates a Doi' do
        post '/dois', valid_attributes, headers

        expect(last_response.status).to eq(201)
        expect(json.dig('data', 'attributes', 'doi')).to eq("10.14454/10703")
        expect(json.dig('data', 'attributes', 'titles')).to eq([{"title"=>"Eating your own Dog Food"}])
        expect(json.dig('data', 'attributes', 'url')).to eq("http://www.bl.uk/pdf/patspec.pdf")
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

      it 'creates a Doi' do
        post '/dois', valid_attributes, headers

        expect(last_response.status).to eq(201)
        expect(json.dig('data', 'attributes', 'doi')).to eq("10.14454/10703")
        expect(json.dig('data', 'attributes', 'creators')).to eq(creators)
        expect(json.dig('data', 'attributes', 'url')).to eq("http://www.bl.uk/pdf/patspec.pdf")
        expect(json.dig('data', 'attributes', 'state')).to eq("findable")
      end
    end

    context 'when doi has unpermitted characters' do
      let(:xml) { Base64.strict_encode64(file_fixture('datacite.xml').read) }
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "doi" => "10.14454/107+03",
              "url" => "http://www.bl.uk/pdf/patspec.pdf",
              "xml" => xml,
              "source" => "test",
              "event" => "publish"
            }
          }
        }
      end

      it 'returns validation error' do
        post '/dois', valid_attributes, headers

        expect(last_response.status).to eq(422)
        expect(json.dig('errors')).to eq([{"source"=>"doi", "title"=>"Is invalid"}])
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

      it 'returns validation error' do
        post '/dois', valid_attributes, headers

        expect(last_response.status).to eq(422)
        expect(json.dig('errors')).to eq([{"source"=>"metadata", "title"=>"Is invalid"}])
      end
    end

    context 'draft doi no url' do
      let(:prefix) { create(:prefix, prefix: "10.14454") }
      let!(:client_prefix) { create(:client_prefix, client: client, prefix: prefix) }

      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "doi" => "10.14454/10704"
            }
          }
        }
      end

      it 'creates a Doi' do
        post '/dois', valid_attributes, headers

        expect(last_response.status).to eq(201)
        expect(json.dig('data', 'attributes', 'doi')).to eq("10.14454/10704")
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

      it 'returns a validation failure message' do
        post '/dois', not_valid_attributes, headers

        expect(last_response.status).to eq(403)
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

      it 'creates a Doi' do
        post '/dois', not_valid_attributes, headers

        expect(last_response.status).to eq(201)
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

      it 'returns a validation failure message' do
        post '/dois', not_valid_attributes, headers

        expect(last_response.status).to eq(422)
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

        it 'validates a Doi' do
          post '/dois/validate', params, headers

          expect(last_response.status).to eq(200)
          expect(json.dig('data', 'attributes', 'doi')).to eq("10.14454/10703")
          expect(json.dig('data', 'attributes', 'titles')).to eq([{"title"=>"Eating your own Dog Food"}])
          expect(json.dig('data', 'attributes', 'dates')).to eq([{"date"=>"2016-12-20", "dateType"=>"Created"}, {"date"=>"2016-12-20", "dateType"=>"Issued"}, {"date"=>"2016-12-20", "dateType"=>"Updated"}])
        end
      end

      context 'validatation fails with unpermitted characters in new DOI' do
        let(:xml) { ::Base64.strict_encode64(File.read(file_fixture('datacite.xml'))) }
        let(:params) do
          {
            "data" => {
              "type" => "dois",
              "attributes" => {
                "doi" => "10.14454/107+03",
                "xml" => xml,
              }
            }
          }
        end

        it 'returns validation error' do
          post '/dois/validate', params, headers

          expect(json.dig('errors')).to eq([{"source"=>"doi", "title"=>"Is invalid"}])
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

        it 'validates a Doi' do
          post '/dois/validate', params, headers

          expect(last_response.status).to eq(200)
          expect(json.dig('data', 'attributes', 'doi')).to eq("10.14454/10703")
          expect(json.dig('data', 'attributes', 'titles')).to eq([{"title"=>"Data from: A new malaria agent in African hominids."}])
          expect(json.dig('data', 'attributes', 'dates')).to eq([{"date"=>"2011", "dateType"=>"Issued"}])
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

        it 'validates a Doi' do
          post '/dois/validate', params, headers

          expect(last_response.status).to eq(200)
          expect(json['errors'].size).to eq(1)
          expect(json['errors'].first).to eq("source"=>"creators", "title"=>"Missing child element(s). expected is ( {http://datacite.org/schema/kernel-4}creator ). at line 4, column 0")
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

        it 'validates a Doi' do
          post '/dois/validate', params, headers

          expect(last_response.status).to eq(200)
          expect(json['errors'].size).to eq(1)
          expect(json['errors'].first).to eq("source"=>"creatorName", "title"=>"This element is not expected. expected is ( {http://datacite.org/schema/kernel-4}affiliation ). at line 16, column 0")
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

        it 'validates a Doi' do
          post '/dois/validate', params, headers

          expect(last_response.status).to eq(200)
          expect(json.dig('data', 'attributes', 'doi')).to eq("10.14454/10703")
          expect(json.dig('data', 'attributes', 'titles')).to eq([{"title"=>"Eating your own Dog Food"}])
          expect(json.dig('data', 'attributes', 'dates')).to eq([{"date"=>"2016-12-20", "dateType"=>"Issued"}])
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

        it 'validates a Doi' do
          post '/dois/validate', params, headers

          expect(last_response.status).to eq(200)
          expect(json.dig('data', 'attributes', 'doi')).to eq("10.14454/10703")
          expect(json.dig('data', 'attributes', 'titles')).to eq([{"title"=>"R Interface to the DataONE REST API"}])
          expect(json.dig('data', 'attributes', 'dates')).to eq([{"date"=>"2016-05-27", "dateType"=>"Issued"}, {"date"=>"2016-05-27", "dateType"=>"Created"}, {"date"=>"2016-05-27", "dateType"=>"Updated"}])
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

        it 'validates a Doi' do
          post '/dois/validate', params, headers

          expect(last_response.status).to eq(200)
          expect(json.dig('data', 'attributes', 'doi')).to eq("10.14454/10703")
          expect(json.dig('data', 'attributes', 'titles')).to eq([{"title"=>"Analysis Tools for Crossover Experiment of UI using Choice Architecture"}])
          expect(json.dig('data', 'attributes', 'dates')).to eq("date"=>"2016-03-27", "dateType"=>"Issued")
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

        it 'validates a Doi' do
          post '/dois/validate', params, headers

          expect(last_response.status).to eq(200)
          expect(json.dig('data', 'attributes', 'doi')).to eq("10.14454/10703")
          expect(json.dig('data', 'attributes', 'titles')).to eq([{"title"=>"Automated quantitative histology reveals vascular morphodynamics during Arabidopsis hypocotyl secondary growth"}])
          expect(json.dig('data', 'attributes', 'dates')).to eq([{"date"=>"2014", "dateType"=>"Issued"}])
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

        it 'validates a Doi' do
          post '/dois/validate', params, headers

          expect(last_response.status).to eq(200)
          expect(json.dig('data', 'attributes', 'doi')).to eq("10.14454/10703")
          expect(json.dig('data', 'attributes', 'titles')).to eq([{"title"=>"Automated quantitative histology reveals vascular morphodynamics during Arabidopsis hypocotyl secondary growth"}])
          expect(json.dig('data', 'attributes', 'dates')).to eq([{"date"=>"2014", "dateType"=>"Issued"}])
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

        it 'validates a Doi' do
          post '/dois/validate', params, headers

          expect(last_response.status).to eq(200)
          expect(json.dig('data', 'attributes', 'doi')).to eq("10.14454/10703")
          expect(json.dig('data', 'attributes', 'titles')).to eq([{"title"=>"Automated quantitative histology reveals vascular morphodynamics during Arabidopsis hypocotyl secondary growth"}])
          expect(json.dig('data', 'attributes', 'dates')).to eq([{"date"=>"2014-02-11", "dateType"=>"Issued"}, {"date"=>"2018-08-23T13:41:49Z", "dateType"=>"Updated"}])
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

        it 'validates a Doi' do
          post '/dois/validate', params, headers

          expect(last_response.status).to eq(200)
          expect(json.dig('data', 'attributes', 'doi')).to eq("10.14454/10703")
          expect(json.dig('data', 'attributes', 'titles')).to eq([{"title"=>"Eating your own Dog Food"}])
          expect(json.dig('data', 'attributes', 'dates')).to eq([{"date"=>"2016-12-20", "dateType"=>"Issued"}, {"date"=>"2016-12-20", "dateType"=>"Created"}, {"date"=>"2016-12-20", "dateType"=>"Updated"}])
        end
      end
    end

    context 'update individual attribute' do
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
            }
          }
        }
      end
      let(:update_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "schemaVersion" => "http://datacite.org/schema/kernel-4",
              "regenerate" => true
            }
          }
        }
      end

      it 'creates a Doi' do
        post '/dois', valid_attributes, headers

        expect(json.dig('data', 'attributes', 'doi')).to eq("10.14454/10703")
        expect(json.dig('data', 'attributes', 'titles')).to eq([{"title"=>"Data from: A new malaria agent in African hominids."}])
        expect(json.dig('data', 'attributes', 'schemaVersion')).to eq("http://datacite.org/schema/kernel-3")

        doc = Nokogiri::XML(Base64.decode64(json.dig('data', 'attributes', 'xml')), nil, 'UTF-8', &:noblanks)
        expect(doc.collect_namespaces).to eq("xmlns" => "http://datacite.org/schema/kernel-3","xmlns:dim" => "http://www.dspace.org/xmlns/dspace/dim","xmlns:dryad" => "http://purl.org/dryad/terms/","xmlns:dspace" => "http://www.dspace.org/xmlns/dspace/dim","xmlns:mets" => "http://www.loc.gov/METS/","xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance")
      end

      # it 'updates to schema 4.0' do
      #   put "/dois/10.14454/10703", params: update_attributes.to_json, headers: headers

      #   expect(json.dig('data', 'attributes', 'doi')).to eq("10.14454/10703")
      #   expect(json.dig('data', 'attributes', 'schemaVersion')).to eq("http://datacite.org/schema/kernel-4")

      #   doc = Nokogiri::XML(Base64.decode64(json.dig('data', 'attributes', 'xml')), nil, 'UTF-8', &:noblanks)
      #   expect(doc.collect_namespaces).to eq("xmlns"=>"http://datacite.org/schema/kernel-4", "xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance")
      # end
    end

    context 'update rightsList' do
      let(:rights_list) { [{ "rights" => "Creative Commons Attribution 3.0", "rightsUri" => "http://creativecommons.org/licenses/by/3.0/", "lang" => "en"}] }
      let(:update_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "rightsList" => rights_list
            }
          }
        }
      end

      it 'updates the Doi' do
        patch "/dois/#{doi.doi}", update_attributes, headers

        expect(json.dig('data', 'attributes', 'rightsList')).to eq(rights_list)
      end
    end

    context 'update subjects' do
      let(:subjects) { [{ "subject" => "80505 Web Technologies (excl. Web Search)",
        "schemeUri" => "http://www.abs.gov.au/ausstats/abs@.nsf/0/6BB427AB9696C225CA2574180004463E",
        "subjectScheme" => "FOR",
        "lang" => "en" }] }
      let(:update_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "subjects" => subjects
            }
          }
        }
      end

      it 'updates the Doi' do
        patch "/dois/#{doi.doi}", update_attributes, headers

        expect(json.dig('data', 'attributes', 'subjects')).to eq(subjects)
      end
    end

    context 'update contentUrl' do
      let(:content_url) { ["s3://cgp-commons-public/topmed_open_access/197bc047-e917-55ed-852d-d563cdbc50e4/NWD165827.recab.cram", "gs://topmed-irc-share/public/NWD165827.recab.cram"] }
      let(:update_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "contentUrl" => content_url
            }
          }
        }
      end

      it 'updates the Doi' do
        patch "/dois/#{doi.doi}", update_attributes, headers

        expect(json.dig('data', 'attributes', 'contentUrl')).to eq(content_url)
      end
    end

    context 'update multiple affiliations' do
      let(:creators) { [{ "name"=>"Ollomi, Benjamin", "affiliation" => [{ "name" => "Cambridge University" }, { "name" => "EMBL-EBI" }] }] }
      let(:update_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "creators" => creators
            }
          }
        }
      end

      it 'updates the Doi' do
        patch "/dois/#{doi.doi}", update_attributes, headers

        expect(json.dig('data', 'attributes', 'creators')).to eq(creators)

        doc = Nokogiri::XML(Base64.decode64(json.dig('data', 'attributes', 'xml')), nil, 'UTF-8', &:noblanks)
        expect(doc.at_css("creators", "creator").to_s + "\n").to eq(
          <<~HEREDOC
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

    context 'update geoLocationPoint' do
      let(:geo_locations) { [
        {
          "geoLocationPoint" => {
            "pointLatitude" => "49.0850736",
            "pointLongitude" => "-123.3300992"
          }
        }] }
      let(:update_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "geoLocations" => geo_locations
            }
          }
        }
      end

      it 'updates the Doi' do
        patch "/dois/#{doi.doi}", update_attributes, headers

        expect(json.dig('data', 'attributes', 'geoLocations')).to eq(geo_locations)

        doc = Nokogiri::XML(Base64.decode64(json.dig('data', 'attributes', 'xml')), nil, 'UTF-8', &:noblanks)
        expect(doc.at_css("geoLocations", "geoLocation").to_s + "\n").to eq(
          <<~HEREDOC
            <geoLocations>
              <geoLocation>
                <geoLocationPoint>
                  <pointLatitude>49.0850736</pointLatitude>
                  <pointLongitude>-123.3300992</pointLongitude>
                </geoLocationPoint>
              </geoLocation>
            </geoLocations>
          HEREDOC
        )
      end
    end

    context 'remove series_information' do
      let(:xml) { File.read(file_fixture('datacite_series_information.xml')) }
      let(:descriptions) { [{ "description" => "Axel is a minimalistic cliff climbing rover that can explore
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
        build a working prototype of a percussive scoop for Axel.", "descriptionType" => "Abstract" }]}
      let(:doi) { create(:doi, client: client, doi: "10.14454/05mb-q396", xml: xml, event: "publish") }
      let(:update_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "descriptions" => descriptions
            }
          }
        }
      end

      it 'updates the Doi' do
        patch "/dois/#{doi.doi}", update_attributes, headers

        expect(json.dig('data', 'attributes', 'descriptions')).to eq(descriptions)
        expect(json.dig('data', 'attributes', 'container')).to be nil
      end
    end

    context 'remove series_information via xml', elasticsearch: true do
      let(:xml) { Base64.strict_encode64(File.read(file_fixture('datacite_series_information.xml'))) }
      let(:xml_new) { Base64.strict_encode64(File.read(file_fixture('datacite_no_series_information.xml'))) }
      let!(:doi) { create(:doi, client: client, doi: "10.14454/05mb-q396", event: "publish") }
      let(:update_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "xml" => xml
            }
          }
        }
      end
      let(:update_attributes_again) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "xml" => xml_new
            }
          }
        }
      end

      before do
        Doi.import
        sleep 1
      end

      it 'updates the Doi' do
        get "/dois/#{doi.doi}", nil, headers

        expect(json.dig('data', 'attributes', 'descriptions')).to eq([{"description"=>"Data from: A new malaria agent in African hominids."}])
        expect(json.dig('data', 'attributes', 'container')).to be nil

        patch "/dois/#{doi.doi}", update_attributes, headers

        expect(json.dig('data', 'attributes', 'descriptions').size).to eq(2)
        expect(json.dig('data', 'attributes', 'descriptions').last).to eq("description"=>"Keck Institute for Space Studies", "descriptionType"=>"SeriesInformation")
        expect(json.dig('data', 'attributes', 'container')).to eq("title"=>"Keck Institute for Space Studies", "type"=>"Series")

        patch "/dois/#{doi.doi}", update_attributes_again, headers

        expect(json.dig('data', 'attributes', 'descriptions').size).to eq(1)
        expect(json.dig('data', 'attributes', 'container')).to be_nil
      end
    end

    context 'landing page' do
      let(:url) { "https://blog.datacite.org/re3data-science-europe/" }
      let(:xml) { Base64.strict_encode64(file_fixture('datacite.xml').read) }
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
          "bodyHasPid" => true
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
              "event" => "publish"
            }
          }
        }
      end

      it 'creates a doi' do
        post '/dois', valid_attributes.to_json, { 'HTTP_ACCEPT'=>'application/vnd.api+json', 'CONTENT_TYPE'=>'application/vnd.api+json', 'HTTP_AUTHORIZATION' => 'Bearer ' + bearer }

        expect(last_response.status).to eq(201)
        expect(json.dig('data', 'attributes', 'url')).to eq(url)
        expect(json.dig('data', 'attributes', 'doi')).to eq("10.14454/10703")
        expect(json.dig('data', 'attributes', 'landingPage')).to eq(landing_page)
        expect(json.dig('data', 'attributes', 'state')).to eq("findable")
      end
    end

    context 'update with landing page info as admin' do
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
          "bodyHasPid" => true
        }
      end
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "landingPage" => landing_page,
              "event" => "publish"
            }
          }
        }
      end

      it 'creates a doi' do
        put "/dois/#{doi.doi}", valid_attributes.to_json, { 'HTTP_ACCEPT'=>'application/vnd.api+json', 'CONTENT_TYPE'=>'application/vnd.api+json', 'HTTP_AUTHORIZATION' => 'Bearer ' + admin_bearer}

        expect(last_response.status).to eq(200)
        expect(json.dig('data', 'attributes', 'doi')).to eq("10.14454/10703")
        expect(json.dig('data', 'attributes', 'landingPage')).to eq(landing_page)
        expect(json.dig('data', 'attributes', 'state')).to eq("findable")
      end
    end

    context 'landing page schema-org-id array' do
      let(:url) { "https://blog.datacite.org/re3data-science-europe/" }
      let(:xml) { Base64.strict_encode64(file_fixture('datacite.xml').read) }
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
            "http://dx.doi.org/10.4225/06/564AB348340D5"
          ],
          "dcIdentifier" => nil,
          "citationDoi" => nil,
          "bodyHasPid" => true
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
              "event" => "publish"
            }
          }
        }
      end

      it 'creates a Doi' do
        post '/dois', valid_attributes.to_json, { 'HTTP_ACCEPT'=>'application/vnd.api+json', 'CONTENT_TYPE'=>'application/vnd.api+json', 'HTTP_AUTHORIZATION' => 'Bearer ' + bearer }

        expect(last_response.status).to eq(201)
        expect(json.dig('data', 'attributes', 'url')).to eq(url)
        expect(json.dig('data', 'attributes', 'doi')).to eq("10.14454/10703")
        expect(json.dig('data', 'attributes', 'landingPage')).to eq(landing_page)
        expect(json.dig('data', 'attributes', 'state')).to eq("findable")
      end
    end
  end

  describe 'DELETE /dois/:id' do
    let(:doi) { create(:doi, client: client, aasm_state: "draft") }

    it 'returns status code 204' do
      delete "/dois/#{doi.doi}", nil, headers

      expect(last_response.status).to eq(204)
      expect(last_response.body).to be_empty
    end
  end

  describe 'DELETE /dois/:id findable state' do
    let(:doi) { create(:doi, client: client, aasm_state: "findable") }

    it 'returns status code 405' do
      delete "/dois/#{doi.doi}", nil, headers

      expect(last_response.status).to eq(405)
      expect(json["errors"]).to eq([{"status"=>"405", "title"=>"Method not allowed"}])
    end
  end

  describe 'POST /dois/set-url', elasticsearch: true do
    let!(:dois) { create_list(:doi, 3, client: client, url: nil) }

    it 'returns dois' do
      post '/dois/set-url', nil, admin_headers

      expect(last_response.status).to eq(200)
      expect(json['message']).to eq("Adding missing URLs queued.")
    end
  end

  describe 'GET /dois/random' do
    it 'returns random doi' do
      get '/dois/random?prefix=10.14454', headers: headers

      expect(last_response.status).to eq(200)
      expect(json['dois'].first).to start_with("10.14454")
    end
  end

  describe 'GET /dois/<doi> linkcheck results', elasticsearch: true do
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
    let!(:doi) { create(:doi, doi: "10.24425/2210181332",
      client: client,
      state: "findable",
      event: 'publish',
      landing_page: landing_page) }

    # Create a different dummy client and a doi with entry associated
    # This is so we can test clients accessing others information
    let(:other_client) { create(:client, provider: provider, symbol: 'DATACITE.DOESNTEXIST', password: 'notarealpassword') }
    let(:other_doi) { create(:doi, doi: "10.24425/2210181332",
      client: other_client,
      state: "findable",
      event: 'publish',
      landing_page: landing_page) }

    before do
      Doi.import
      sleep 1
    end

    context 'anonymous get' do
      let(:headers) { { 'HTTP_ACCEPT'=>'application/vnd.api+json' } }

      it 'returns without landing page results' do
        get "/dois/#{doi.doi}", nil, headers

        expect(json.dig('data', 'attributes', 'doi')).to eq(doi.doi)
        expect(json.dig('data', 'attributes', 'landingPage')).to eq(nil)
      end
    end

    context 'client authorised get own dois' do
      let(:bearer) { User.generate_token(role_id: "client_admin", client_id: client.symbol.downcase) }
      let(:headers) { { 'HTTP_ACCEPT'=>'application/vnd.api+json', 'HTTP_AUTHORIZATION' => 'Bearer ' + bearer } }

      it 'returns with landing page results' do
        get "/dois/#{doi.doi}", nil, headers

        expect(json.dig('data', 'attributes', 'doi')).to eq(doi.doi)
        expect(json.dig('data', 'attributes', 'landingPage')).to eq(landing_page)
      end
    end


    context 'client authorised try get diff dois landing data' do
      let(:bearer) { User.generate_token(role_id: "client_admin", client_id: client.symbol.downcase) }
      let(:headers) { { 'HTTP_ACCEPT'=>'application/vnd.api+json', 'HTTP_AUTHORIZATION' => 'Bearer ' + bearer } }

      it 'returns with landing page results' do
        get "/dois/#{other_doi.doi}", nil, headers

        expect(json.dig('data', 'attributes', 'doi')).to eq(other_doi.doi)
        expect(json.dig('data', 'attributes', 'landingPage')).to eq(nil)
      end
    end

    context 'authorised staff admin read' do
      let(:bearer) { User.generate_token(role_id: "client_admin", client_id: client.symbol.downcase) }
      let(:headers) { { 'HTTP_ACCEPT'=>'application/vnd.api+json', 'HTTP_AUTHORIZATION' => 'Bearer ' + admin_bearer } }

      it 'returns with landing page results' do
        get "/dois/#{doi.doi}", nil, headers

        expect(json.dig('data', 'attributes', 'doi')).to eq(doi.doi)
        expect(json.dig('data', 'attributes', 'landingPage')).to eq(landing_page)
      end
    end

  end

  describe 'GET /dois/random?prefix' do
    it 'returns random doi with prefix' do
      get "/dois/random?prefix=#{prefix.prefix}", nil, headers

      expect(last_response.status).to eq(200)
      expect(json['dois'].first).to start_with("10.14454")
    end
  end

  describe 'GET /dois/random?number' do
    let(:number) { 122149076 }

    it 'returns predictable doi' do
      get "/dois/random?prefix=10.14454&number=#{number}", nil, headers

      expect(last_response.status).to eq(200)
      expect(json['dois'].first).to eq("10.14454/3mfp-6m52")
    end
  end

  describe 'GET /dois/DOI/get-url', vcr: true, elasticsearch: true do
    context 'it works' do
      let!(:doi) { create(:doi, client: client, doi: "10.5438/fj3w-0shd", url: "https://blog.datacite.org/data-driven-development/", event: "publish") }

      before do
        Doi.import
        sleep 1
      end

      it 'returns url' do
        get "/dois/#{doi.doi}/get-url", nil, headers

        expect(json["url"]).to eq("https://blog.datacite.org/data-driven-development/")
        expect(last_response.status).to eq(200)
      end
    end

    context 'no password' do
      let!(:doi) { create(:doi, client: client, doi: "10.14454/05mb-q396", event: "publish") }

      before do
        Doi.import
        sleep 1
      end

      it 'returns error' do
        get "/dois/#{doi.doi}/get-url", nil, { 'HTTP_ACCEPT'=>'application/vnd.api+json' }

        expect(last_response.status).to eq(401)
        expect(json['errors']).to eq([{"status"=>"401", "title"=>"Bad credentials."}])
      end
    end

    context 'wrong password' do
      let!(:doi) { create(:doi, client: client, doi: "10.14454/05mb-q396", event: "publish") }
      let(:credentials) { client.encode_auth_param(username: client.symbol.downcase, password: "12345") }

      before do
        Doi.import
        sleep 1
      end

      it 'returns error' do
        get "/dois/#{doi.doi}/get-url", nil, { 'HTTP_ACCEPT'=>'application/vnd.api+json', 'HTTP_AUTHORIZATION' => 'Basic ' + credentials }

        expect(last_response.status).to eq(401)
        expect(json['errors']).to eq([{"status"=>"401", "title"=>"Bad credentials."}])
      end
    end

    context 'no permission' do
      let(:other_client) { create(:client, provider: provider) }
      let!(:doi) { create(:doi, client: other_client, doi: "10.14454/8syz-ym47", event: "publish") }

      before do
        Doi.import
        sleep 1
      end

      it 'returns error' do
        get "/dois/#{doi.doi}/get-url", nil, headers

        expect(last_response.status).to eq(403)
        expect(json['errors']).to eq([{"status"=>"403", "title"=>"You are not authorized to access this resource."}])
      end
    end

    context 'not found' do
      let!(:doi) { create(:doi, client: client, doi: "10.14454/61y1-e521", event: "publish") }

      before do
        Doi.import
        sleep 1
      end

      it 'returns not found' do
        get "/dois/#{doi.doi}/get-url", nil, headers

        expect(last_response.status).to eq(404)
        expect(json['errors']).to eq([{"status"=>404, "title"=>"Not found"}])
      end
    end

    context 'draft doi' do
      let!(:doi) { create(:doi, client: client, doi: "10.14454/61y1-e521") }

      before do
        Doi.import
        sleep 1
      end

      it 'returns not found' do
        get "/dois/#{doi.doi}/get-url", nil, headers

        expect(last_response.status).to eq(200)
        expect(json['url']).to eq(doi.url)
      end
    end

    context 'not DataCite DOI' do
      let(:doi) { create(:doi, client: client, doi: "10.1371/journal.pbio.2001414", event: "publish") }

      it 'returns nil' do
        get "/dois/#{doi.doi}/get-url", nil, headers

        expect(last_response.status).to eq(404)
        expect(json['url']).to be_nil
      end
    end
  end

  describe 'GET /dois/get-dois', vcr: true do
    let(:prefix) { create(:prefix, prefix: "10.5438") }
    let!(:client_prefix) { create(:client_prefix, prefix: prefix, client: client) }

    it 'returns all dois' do
      get "/dois/get-dois", nil, headers

      expect(last_response.status).to eq(200)
      expect(json["dois"].length).to eq(443)
      expect(json["dois"].first).to eq("10.5438/0000-00SS")
    end
  end

  describe 'GET /dois/get-dois no authentication', vcr: true do
    it 'returns error message' do
      get "/dois/get-dois"

      expect(last_response.status).to eq(401)
      expect(json["errors"]).to eq([{"status"=>"401", "title"=>"Bad credentials."}])
    end
  end

  describe "content_negotation", type: :request, elasticsearch: true do
    let(:provider) { create(:provider, symbol: "DATACITE") }
    let(:client) { create(:client, provider: provider, symbol: ENV['MDS_USERNAME'], password: ENV['MDS_PASSWORD']) }
    let(:bearer) { Client.generate_token(role_id: "client_admin", uid: client.symbol, provider_id: provider.symbol.downcase, client_id: client.symbol.downcase, password: client.password) }
    let!(:doi) { create(:doi, client: client, aasm_state: "findable") }

    before do
      Doi.import
      sleep 1
    end

    context "no permission" do
      let(:doi) { create(:doi) }

      it 'returns error message' do
        get "/dois/#{doi.doi}", nil, { "HTTP_ACCEPT" => "application/vnd.jats+xml", 'HTTP_AUTHORIZATION' => 'Bearer ' + bearer }

        expect(last_response.status).to eq(403)
        expect(json["errors"]).to eq([{"status"=>"403", "title"=>"You are not authorized to access this resource."}])
      end
    end

    context "no authentication" do
      let(:doi) { create(:doi) }

      it 'returns error message' do
        get "/dois/#{doi.doi}", nil, { "HTTP_ACCEPT" => "application/vnd.jats+xml" }

        expect(last_response.status).to eq(401)
        expect(json["errors"]).to eq([{"status"=>"401", "title"=>"Bad credentials."}])
      end
    end

    context "application/vnd.jats+xml" do
      it 'returns the Doi' do
        get "/dois/#{doi.doi}", nil, { "HTTP_ACCEPT" => "application/vnd.jats+xml", 'HTTP_AUTHORIZATION' => 'Bearer ' + bearer }

        expect(last_response.status).to eq(200)
        jats = Maremma.from_xml(last_response.body).fetch("element_citation", {})
        expect(jats.dig("publication_type")).to eq("data")
        expect(jats.dig("data_title")).to eq("Data from: A new malaria agent in African hominids.")
      end
    end

    context "application/vnd.jats+xml link" do
      it 'returns the Doi' do
        get "/dois/application/vnd.jats+xml/#{doi.doi}"

        expect(last_response.status).to eq(200)
        jats = Maremma.from_xml(last_response.body).fetch("element_citation", {})
        expect(jats.dig("publication_type")).to eq("data")
        expect(jats.dig("data_title")).to eq("Data from: A new malaria agent in African hominids.")
      end
    end

    context "application/vnd.datacite.datacite+xml" do
      it 'returns the Doi' do
        get "/dois/#{doi.doi}", nil, { "HTTP_ACCEPT" => "application/vnd.datacite.datacite+xml", 'HTTP_AUTHORIZATION' => 'Bearer ' + bearer  }

        expect(last_response.status).to eq(200)
        data = Maremma.from_xml(last_response.body).to_h.fetch("resource", {})
        expect(data.dig("xmlns")).to eq("http://datacite.org/schema/kernel-4")
        expect(data.dig("publisher")).to eq("Dryad Digital Repository")
        expect(data.dig("titles", "title")).to eq("Data from: A new malaria agent in African hominids.")
      end
    end

    context "application/vnd.datacite.datacite+xml link" do
      it 'returns the Doi' do
        get "/dois/application/vnd.datacite.datacite+xml/#{doi.doi}"

        expect(last_response.status).to eq(200)
        data = Maremma.from_xml(last_response.body).to_h.fetch("resource", {})
        expect(data.dig("xmlns")).to eq("http://datacite.org/schema/kernel-4")
        expect(data.dig("publisher")).to eq("Dryad Digital Repository")
        expect(data.dig("titles", "title")).to eq("Data from: A new malaria agent in African hominids.")
      end
    end

    context "application/vnd.datacite.datacite+xml schema 3" do
      let(:xml) { file_fixture('datacite_schema_3.xml').read }
      let(:doi) { create(:doi, xml: xml, client: client, regenerate: false) }

      it 'returns the Doi' do
        get "/dois/#{doi.doi}", nil, { "HTTP_ACCEPT" => "application/vnd.datacite.datacite+xml", 'HTTP_AUTHORIZATION' => 'Bearer ' + bearer  }

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
      it 'returns error message' do
        get "/dois/xxx", nil, { "HTTP_ACCEPT" => "application/vnd.datacite.datacite+xml", 'HTTP_AUTHORIZATION' => 'Bearer ' + bearer  }

        expect(last_response.status).to eq(404)
        expect(json["errors"]).to eq([{"status"=>"404", "title"=>"The resource you are looking for doesn't exist."}])
      end
    end

    context "application/vnd.datacite.datacite+json" do
      it 'returns the Doi' do
        get "/dois/#{doi.doi}", nil, { "HTTP_ACCEPT" => "application/vnd.datacite.datacite+json", 'HTTP_AUTHORIZATION' => 'Bearer ' + bearer  }

        expect(last_response.status).to eq(200)
        expect(json["doi"]).to eq(doi.doi)
      end
    end

    context "application/vnd.datacite.datacite+json link" do
      it 'returns the Doi' do
        get "/dois/application/vnd.datacite.datacite+json/#{doi.doi}"

        expect(last_response.status).to eq(200)
        expect(json["doi"]).to eq(doi.doi)
      end
    end

    context "application/vnd.crosscite.crosscite+json" do
      it 'returns the Doi' do
        get "/dois/#{doi.doi}", nil, { "HTTP_ACCEPT" => "application/vnd.crosscite.crosscite+json", 'HTTP_AUTHORIZATION' => 'Bearer ' + bearer  }

        expect(last_response.status).to eq(200)
        expect(json["doi"]).to eq(doi.doi)
      end
    end

    context "application/vnd.crosscite.crosscite+json link" do
      it 'returns the Doi' do
        get "/dois/application/vnd.crosscite.crosscite+json/#{doi.doi}"

        expect(last_response.status).to eq(200)
        expect(json["doi"]).to eq(doi.doi)
      end
    end

    context "application/vnd.schemaorg.ld+json" do
      it 'returns the Doi' do
        get "/dois/#{doi.doi}", nil, { "HTTP_ACCEPT" => "application/vnd.schemaorg.ld+json", 'HTTP_AUTHORIZATION' => 'Bearer ' + bearer  }

        expect(last_response.status).to eq(200)
        expect(json["@type"]).to eq("Dataset")
      end
    end

    context "application/vnd.schemaorg.ld+json link" do
      it 'returns the Doi' do
        get "/dois/application/vnd.schemaorg.ld+json/#{doi.doi}"

        expect(last_response.status).to eq(200)
        expect(json["@type"]).to eq("Dataset")
      end
    end

    context "application/vnd.citationstyles.csl+json" do
      it 'returns the Doi' do
        get "/dois/#{doi.doi}", nil, { "HTTP_ACCEPT" => "application/vnd.citationstyles.csl+json", 'HTTP_AUTHORIZATION' => 'Bearer ' + bearer  }

        expect(last_response.status).to eq(200)
        expect(json["type"]).to eq("dataset")
      end
    end

    context "application/vnd.citationstyles.csl+json link" do
      it 'returns the Doi' do
        get "/dois/application/vnd.citationstyles.csl+json/#{doi.doi}"

        expect(last_response.status).to eq(200)
        expect(json["type"]).to eq("dataset")
      end
    end

    context "application/x-research-info-systems" do
      it 'returns the Doi' do
        get "/dois/#{doi.doi}", nil, { "HTTP_ACCEPT" => "application/x-research-info-systems", 'HTTP_AUTHORIZATION' => 'Bearer ' + bearer  }

        expect(last_response.status).to eq(200)
        expect(last_response.body).to start_with("TY  - DATA")
      end
    end

    context "application/x-research-info-systems link" do
      it 'returns the Doi' do
        get "/dois/application/x-research-info-systems/#{doi.doi}"

        expect(last_response.status).to eq(200)
        expect(last_response.body).to start_with("TY  - DATA")
      end
    end

    context "application/x-bibtex" do
      it 'returns the Doi' do
        get "/dois/#{doi.doi}", nil, { "HTTP_ACCEPT" => "application/x-bibtex", 'HTTP_AUTHORIZATION' => 'Bearer ' + bearer  }

        expect(last_response.status).to eq(200)
        expect(last_response.body).to start_with("@misc{https://doi.org/#{doi.doi.downcase}")
      end
    end

    context "application/x-bibtex link" do
      it 'returns the Doi' do
        get "/dois/application/x-bibtex/#{doi.doi}"

        expect(last_response.status).to eq(200)
        expect(last_response.body).to start_with("@misc{https://doi.org/#{doi.doi.downcase}")
      end
    end

    context "text/csv" do
      it 'returns the Doi' do
        get "/dois/#{doi.doi}", nil, { "HTTP_ACCEPT" => "text/csv", 'HTTP_AUTHORIZATION' => 'Bearer ' + bearer  }

        expect(last_response.status).to eq(200)
        expect(last_response.body).to include(doi.doi)
      end
    end

    context "text/csv link" do
      it 'returns the Doi' do
        get "/dois/text/csv/#{doi.doi}"

        expect(last_response.status).to eq(200)
        expect(last_response.body).to include(doi.doi)
      end
    end

    context "text/x-bibliography", vcr: true do
      context "default style" do
        it 'returns the Doi' do
          get "/dois/#{doi.doi}", nil, { "HTTP_ACCEPT" => "text/x-bibliography", 'HTTP_AUTHORIZATION' => 'Bearer ' + bearer  }

          expect(last_response.status).to eq(200)
          expect(last_response.body).to start_with("Ollomo, B.")
        end
      end

      context "default style link" do
        it 'returns the Doi' do
          get "/dois/text/x-bibliography/#{doi.doi}"

          expect(last_response.status).to eq(200)
          expect(last_response.body).to start_with("Ollomo, B.")
        end
      end

      context "ieee style" do
        it 'returns the Doi' do
          get "/dois/#{doi.doi}?style=ieee", nil, { "HTTP_ACCEPT" => "text/x-bibliography", 'HTTP_AUTHORIZATION' => 'Bearer ' + bearer  }

          expect(last_response.status).to eq(200)
          expect(last_response.body).to start_with("B. Ollomo")
        end
      end

      context "ieee style link" do
        it 'returns the Doi' do
          get "/dois/text/x-bibliography/#{doi.doi}?style=ieee"

          expect(last_response.status).to eq(200)
          expect(last_response.body).to start_with("B. Ollomo")
        end
      end

      context "style and locale" do
        it 'returns the Doi' do
          get "/dois/#{doi.doi}?style=vancouver&locale=de", nil, { "HTTP_ACCEPT" => "text/x-bibliography", 'HTTP_AUTHORIZATION' => 'Bearer ' + bearer  }

          expect(last_response.status).to eq(200)
          expect(last_response.body).to start_with("Ollomo B")
        end
      end
    end

    context "unknown content type" do
      it 'returns the Doi' do
        get "/dois/#{doi.doi}", nil, { "HTTP_ACCEPT" => "application/vnd.ms-excel", 'HTTP_AUTHORIZATION' => 'Bearer ' + bearer }

        expect(last_response.status).to eq(406)
        expect(json["errors"]).to eq([{"status"=>"406", "title"=>"The content type is not recognized."}])
      end
    end

    context "missing content type" do
      it 'returns the Doi' do
        get "/dois/#{doi.doi}", nil, { 'HTTP_AUTHORIZATION' => 'Bearer ' + bearer  }

        expect(last_response.status).to eq(200)
        expect(json.dig('data', 'attributes', 'doi')).to eq(doi.doi.downcase)
      end
    end
  end
end
