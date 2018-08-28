require 'rails_helper'

describe "dois", type: :request do
  let(:admin) { create(:provider, symbol: "ADMIN") }
  let(:admin_bearer) { Client.generate_token(role_id: "staff_admin", uid: admin.symbol, password: admin.password) }
  let(:admin_headers) { {'ACCEPT'=>'application/vnd.api+json', 'CONTENT_TYPE'=>'application/vnd.api+json', 'Authorization' => 'Bearer ' + admin_bearer}}

  let(:provider) { create(:provider, symbol: "DATACITE") }
  let(:client) { create(:client, provider: provider, symbol: ENV['MDS_USERNAME'], password: ENV['MDS_PASSWORD']) }
  let(:prefix) { create(:prefix, prefix: "10.14454") }
  let!(:client_prefix) { create(:client_prefix, client: client, prefix: prefix) }
  let!(:dois) { create_list(:doi, 3, client: client) }
  let(:doi) { create(:doi, client: client) }
  let(:bearer) { Client.generate_token(role_id: "client_admin", uid: client.symbol, provider_id: provider.symbol.downcase, client_id: client.symbol.downcase, password: client.password) }
  let(:headers) { { 'ACCEPT'=>'application/vnd.api+json', 'CONTENT_TYPE'=>'application/vnd.api+json', 'Authorization' => 'Bearer ' + bearer }}

  # describe 'GET /dois', elasticsearch: true do
  #   before do
  #     sleep 1
  #     get '/dois', headers: headers
  #   end

  #   it 'returns dois' do
  #     expect(json['data'].size).to eq(3)
  #   end

  #   it 'returns status code 200' do
  #     expect(response).to have_http_status(200)
  #   end
  # end

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
  end

  describe 'PATCH /dois/:id' do
    let(:bearer) { User.generate_token(role_id: "client_admin", client_id: client.symbol.downcase) }
    let(:headers) { {'ACCEPT'=>'application/vnd.api+json', 'CONTENT_TYPE'=>'application/vnd.api+json', 'Authorization' => 'Bearer ' + bearer}}

    before(:each) do
      Rails.cache.clear
    end

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
        expect(json.dig('data', 'attributes', 'title')).to eq("Eating your own Dog Food")

        xml = Maremma.from_xml(Base64.decode64(json.dig('data', 'attributes', 'xml'))).fetch("resource", {})
        expect(xml.dig("titles", "title")).to eq("Eating your own Dog Food")
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end

      it 'sets state to draft' do
        expect(json.dig('data', 'attributes', 'state')).to eq("draft")
      end
    end

    context 'when the record exists no creator validate' do
      let(:xml) { Base64.strict_encode64(file_fixture('datacite_missing_creator.xml').read) }
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "url" => "http://www.bl.uk/pdf/pat.pdf",
              "xml" => xml,
              "validate" => "true"
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
      before { put "/dois/#{doi.doi}", params: valid_attributes.to_json, headers: headers }

      it 'returns error' do
        expect(json["errors"]).to eq([{"source"=>"creators", "title"=>"Missing child element(s). expected is ( {http://datacite.org/schema/kernel-4}creator ). at line 4, column 0"}])
      end

      it 'returns status code 422' do
        expect(response).to have_http_status(422)
      end
    end

    context 'when the record exists https://github.com/datacite/lupo/issues/89' do
      let(:doi) { create(:doi, doi: "10.24425/119496", client: client, state: "registered") }
      let(:valid_attributes) {file_fixture('datacite_89.json').read}

      before { put "/dois/#{doi.doi}", params: valid_attributes, headers: headers }

      it 'returns no errors' do
        expect(json.dig('data', 'attributes', 'doi')).to eq(doi.doi)
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end
    end

    context 'NoMethodError https://github.com/datacite/lupo/issues/84' do
      let(:doi_id) { "10.14454/m9.figshare.6839054.v1" }
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "url"=> "https://figshare.com/articles/Additional_file_1_of_Contemporary_ancestor_Adaptive_divergence_from_standing_genetic_variation_in_Pacific_marine_threespine_stickleback/6839054/1",
              "event" => "publish"
            },
            "relationships" => {
              "client" => {
                "data" => {
                  "type" => "clients",
                  "id" => client.symbol.downcase
                }
              }
            }
          }
        }
      end

      before { put "/dois/#{doi_id}", params: valid_attributes.to_json, headers: headers }

      it 'returns no errors' do
        expect(json.dig('data', 'attributes', 'doi')).to eq(doi_id)
      end

      it 'returns status code 201' do
        expect(response).to have_http_status(201)
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
              "xml" => xml
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
      before { put "/dois/#{doi_id}", params: valid_attributes.to_json, headers: headers }

      it 'creates the record' do
        expect(json.dig('data', 'attributes', 'url')).to eq("http://www.bl.uk/pdf/pat.pdf")
        expect(json.dig('data', 'attributes', 'doi')).to eq(doi_id.downcase)
        expect(json.dig('data', 'attributes', 'title')).to eq("Eating your own Dog Food")

        xml = Maremma.from_xml(Base64.decode64(json.dig('data', 'attributes', 'xml'))).fetch("resource", {})
        expect(xml.dig("titles", "title")).to eq("Eating your own Dog Food")
      end

      it 'returns status code 201' do
        expect(response).to have_http_status(201)
      end

      it 'sets state to draft' do
        expect(json.dig('data', 'attributes', 'state')).to eq("draft")
      end
    end

    context 'when the record doesn\'t exist no creator validate' do
      let(:doi_id) { "10.14454/077d-fj48" }
      let(:xml) { Base64.strict_encode64(file_fixture('datacite_missing_creator.xml').read) }
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "url" => "http://www.bl.uk/pdf/pat.pdf",
              "xml" => xml,
              "validate" => "true"
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
        expect(json.dig('data', 'attributes', 'title')).to eq("Automated quantitative histology reveals vascular morphodynamics during Arabidopsis hypocotyl secondary growth")
      
        xml = Maremma.from_xml(Base64.decode64(json.dig('data', 'attributes', 'xml'))).fetch("resource", {})
        expect(xml.dig("titles", "title")).to eq("Automated quantitative histology reveals vascular morphodynamics during Arabidopsis hypocotyl secondary growth")
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
      let(:title) { "Submitted chemical data for InChIKey=YAPQBXQYLJRXSA-UHFFFAOYSA-N" }
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "url" => "http://www.bl.uk/pdf/pat.pdf",
              "xml" => xml,
              "title" => title,
              "event" => "register"
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
      before { patch "/dois/#{doi.doi}", params: valid_attributes.to_json, headers: headers }

      it 'updates the record' do
        expect(json.dig('data', 'attributes', 'url')).to eq("http://www.bl.uk/pdf/pat.pdf")
        expect(json.dig('data', 'attributes', 'doi')).to eq(doi.doi.downcase)
        expect(json.dig('data', 'attributes', 'title')).to eq(title)

        xml = Maremma.from_xml(Base64.decode64(json.dig('data', 'attributes', 'xml'))).fetch("resource", {})
        expect(xml.dig("titles", "title")).to eq(title)
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end

      it 'sets state to registered' do
        expect(json.dig('data', 'attributes', 'state')).to eq("registered")
      end
    end

    context 'when the author changes' do
      let(:xml) { Base64.strict_encode64(file_fixture('datacite.xml').read) }
      let(:author) { [{ "name"=>"Ollomi, Benjamin" }, { "name"=>"Duran, Patrick" }] }
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "url" => "http://www.bl.uk/pdf/pat.pdf",
              "xml" => xml,
              "author" => author,
              "event" => "register"
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
      before { patch "/dois/#{doi.doi}", params: valid_attributes.to_json, headers: headers }

      it 'updates the record' do
        expect(json.dig('data', 'attributes', 'url')).to eq("http://www.bl.uk/pdf/pat.pdf")
        expect(json.dig('data', 'attributes', 'doi')).to eq(doi.doi.downcase)
        expect(json.dig('data', 'attributes', 'author')).to eq(author)

        xml = Maremma.from_xml(Base64.decode64(json.dig('data', 'attributes', 'xml'))).fetch("resource", {})
        expect(xml.dig("creators", "creator")).to eq([{"creatorName"=>"Ollomi, Benjamin"}, {"creatorName"=>"Duran, Patrick"}])
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end

      it 'sets state to registered' do
        expect(json.dig('data', 'attributes', 'state')).to eq("registered")
      end
    end

    context 'when we transfer a DOI' do
      let(:doi) { create(:doi, doi: "10.24425/119495", client: client, state: "registered") }
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
        puts json
        expect(response).to have_http_status(200)
        expect(json.dig('data', 'attributes', 'doi')).to eq(doi.doi)
      end

      it 'updates the client id' do
        expect(json.dig('data', 'relationships', 'client','data','id')).to eq(new_client.symbol.downcase)
      end
    end

    context 'when the resource_type_general changes' do
      let(:xml) { Base64.strict_encode64(file_fixture('datacite.xml').read) }
      let(:resource_type_general) { "data-paper" }
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "url" => "http://www.bl.uk/pdf/pat.pdf",
              "xml" => xml,
              "event" => "register"
            },
            "relationships"=> {
              "client"=>  {
                "data"=> {
                  "type"=> "clients",
                  "id"=> client.symbol.downcase
                }
              },
              "resource-type"=>  {
                "data"=> {
                  "type"=> "resource-types",
                  "id"=> resource_type_general
                }
              }
            }
          }
        }
      end
      before { patch "/dois/#{doi.doi}", params: valid_attributes.to_json, headers: headers }

      it 'updates the record' do
        expect(json.dig('data', 'attributes', 'url')).to eq("http://www.bl.uk/pdf/pat.pdf")
        expect(json.dig('data', 'attributes', 'doi')).to eq(doi.doi.downcase)
        # expect(json.dig('data', 'relationships', 'resource-type')).to eq(2)

        xml = Maremma.from_xml(Base64.decode64(json.dig('data', 'attributes', 'xml'))).fetch("resource", {})
        expect(xml.dig("resourceType")).to eq("resourceTypeGeneral"=>"DataPaper", "__content__"=>"BlogPosting")
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end

      it 'sets state to registered' do
        expect(json.dig('data', 'attributes', 'state')).to eq("registered")
      end
    end
  end

  describe 'POST /dois' do
    before(:each) do
      Rails.cache.clear
    end
    
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
              "event" => "register"
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
        expect(json.dig('data', 'attributes', 'title')).to eq("Eating your own Dog Food")
        expect(json.dig('data', 'attributes', 'schema-version')).to eq("http://datacite.org/schema/kernel-4")
        expect(json.dig('data', 'attributes', 'source')).to eq("test")
        expect(json.dig('data', 'relationships', 'resource-type', 'data', 'id')).to eq("text")

        xml = Maremma.from_xml(Base64.decode64(json.dig('data', 'attributes', 'xml'))).fetch("resource", {})
        expect(xml.dig("resourceType")).to eq("resourceTypeGeneral"=>"Text", "__content__"=>"BlogPosting")
      end

      it 'returns status code 201' do
        expect(response).to have_http_status(201)
      end

      it 'sets state to registered' do
        expect(json.dig('data', 'attributes', 'state')).to eq("registered")
      end
    end

    # context 'schema_org' do
    #   let(:xml) { Base64.strict_encode64(file_fixture('schema_org_topmed.json').read) }
    #   let(:valid_attributes) do
    #     {
    #       "data" => {
    #         "type" => "dois",
    #         "attributes" => {
    #           "url" => "https://ors.datacite.org/doi:/10.14454/8na3-9s47",
    #           "xml" => xml,
    #           "source" => "test",
    #           "event" => "register"
    #         }
    #       },
    #       "relationships"=> {
    #         "client"=>  {
    #           "data"=> {
    #             "type"=> "clients",
    #             "id"=> client.symbol.downcase
    #           }
    #         }
    #       }
    #     }
    #   end
      
    #   before { patch "/dois/10.14454/8na3-9s47", params: valid_attributes.to_json, headers: headers }

    #   it 'updates the record' do
    #     expect(json.dig('data', 'attributes', 'url')).to eq("http://www.bl.uk/pdf/pat.pdf")
    #     expect(json.dig('data', 'attributes', 'doi')).to eq(doi.doi.downcase)
    #     expect(json.dig('data', 'attributes', 'title')).to eq("Eating your own Dog Food")

    #     xml = Maremma.from_xml(Base64.decode64(json.dig('data', 'attributes', 'xml'))).fetch("resource", {})
    #     expect(xml.dig("titles", "title")).to eq("Eating your own Dog Food")
    #   end

    #   it 'returns status code 200' do
    #     puts response.body
    #     expect(response).to have_http_status(200)
    #   end

    #   it 'sets state to draft' do
    #     expect(json.dig('data', 'attributes', 'state')).to eq("draft")
    #   end
    # end

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
              "event" => "register"
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
        expect(json.dig('data', 'attributes', 'title')).to eq("Data from: A new malaria agent in African hominids.")
        expect(json.dig('data', 'attributes', 'source')).to eq("test")
        # expect(json.dig('data', 'attributes', 'schema-version')).to eq("http://datacite.org/schema/kernel-3")
      end

      it 'returns status code 201' do
        expect(response).to have_http_status(201)
      end

      it 'sets state to registered' do
        expect(json.dig('data', 'attributes', 'state')).to eq("registered")
      end
    end

    context 'when the request is a large xml file' do
      let(:xml) { Base64.strict_encode64(file_fixture('large_file.xml').read) }
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "doi" => "10.14454/10703",
              "url" => "http://www.bl.uk/pdf/patspec.pdf",
              "xml" => xml,
              "event" => "register"
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
        expect(json.dig('data', 'attributes', 'title')).to eq("A dataset with a large file for testing purpose. Will be a but over 2.5 MB")
      end

      it 'returns status code 201' do
        expect(response).to have_http_status(201)
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
              "event" => "register"
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
        expect(json.dig('data', 'attributes', 'doi')).to eq("10.14454/10703")
        expect(json.dig('data', 'attributes', 'title')).to eq("LAMMPS Data-File Generator")
        # expect(json.dig('data', 'attributes', 'schema-version')).to eq("http://datacite.org/schema/kernel-3")
      end

      it 'returns status code 201' do
        expect(response).to have_http_status(201)
      end

      it 'sets state to registered' do
        expect(json.dig('data', 'attributes', 'state')).to eq("registered")
      end
    end

    context 'when the request uses namespaced xml and the title changes' do
      let(:title) { "Referee report. For: RESEARCH-3482 [version 5; referees: 1 approved, 1 approved with reservations]" }
      let(:xml) { Base64.strict_encode64(file_fixture('ns0.xml').read) }
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "doi" => "10.14454/10703",
              "url" => "http://www.bl.uk/pdf/patspec.pdf",
              "xml" => xml,
              "title" => title,
              "event" => "register"
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
        expect(json.dig('data', 'attributes', 'doi')).to eq("10.14454/10703")
        expect(json.dig('data', 'attributes', 'title')).to eq("Referee report. For: RESEARCH-3482 [version 5; referees: 1 approved, 1 approved with reservations]")
        # expect(json.dig('data', 'attributes', 'schema-version')).to eq("http://datacite.org/schema/kernel-3")
      end

      it 'returns status code 201' do
        expect(response).to have_http_status(201)
      end

      it 'sets state to registered' do
        expect(json.dig('data', 'attributes', 'state')).to eq("registered")
      end
    end


    context 'when the title changes' do
      let(:title) { "Referee report. For: RESEARCH-3482 [version 5; referees: 1 approved, 1 approved with reservations]" }
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
              "title" => title,
              "event" => "register"
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
        expect(json.dig('data', 'attributes', 'doi')).to eq("10.14454/10703")
        expect(json.dig('data', 'attributes', 'title')).to eq("Referee report. For: RESEARCH-3482 [version 5; referees: 1 approved, 1 approved with reservations]")
        expect(json.dig('data', 'attributes', 'url')).to eq("http://www.bl.uk/pdf/patspec.pdf")
        expect(json.dig('data', 'attributes', 'source')).to eq("test")

        xml = Maremma.from_xml(Base64.decode64(json.dig('data', 'attributes', 'xml'))).fetch("resource", {})
        expect(xml.dig("titles", "title")).to eq(title)
      end

      it 'returns status code 201' do
        expect(response).to have_http_status(201)
      end

      it 'sets state to registered' do
        expect(json.dig('data', 'attributes', 'state')).to eq("registered")
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
              "event" => "register"
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
        expect(json.dig('data', 'attributes', 'doi')).to eq("10.14454/10703")
        expect(json.dig('data', 'attributes', 'url')).to eq(url)
      end

      it 'returns status code 201' do
        expect(response).to have_http_status(201)
      end

      it 'sets state to registered' do
        expect(json.dig('data', 'attributes', 'state')).to eq("registered")
      end
    end

    context 'when the title changes to nil' do
      let(:xml) { Base64.strict_encode64(file_fixture('datacite.xml').read) }
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "doi" => "10.14454/10703",
              "url" => "http://www.bl.uk/pdf/patspec.pdf",
              "xml" => xml,
              "title" => nil,
              "event" => "register"
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
        expect(json.dig('data', 'attributes', 'doi')).to eq("10.14454/10703")
        expect(json.dig('data', 'attributes', 'title')).to eq("Eating your own Dog Food")
        expect(json.dig('data', 'attributes', 'url')).to eq("http://www.bl.uk/pdf/patspec.pdf")

        xml = Maremma.from_xml(Base64.decode64(json.dig('data', 'attributes', 'xml'))).fetch("resource", {})
        expect(xml.dig("titles", "title")).to eq("Eating your own Dog Food")
      end

      it 'returns status code 201' do
        expect(response).to have_http_status(201)
      end

      it 'sets state to registered' do
        expect(json.dig('data', 'attributes', 'state')).to eq("registered")
      end
    end

    context 'when the title changes to blank' do
      let(:xml) { Base64.strict_encode64(file_fixture('datacite.xml').read) }
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "doi" => "10.14454/10703",
              "url" => "http://www.bl.uk/pdf/patspec.pdf",
              "xml" => xml,
              "title" => '',
              "event" => "register"
            },
            "relationships"=> {
              "client"=>  {
                "data"=> {
                  "type"=> "clients",
                  "id"=> client.uid
                }
              }
            }
          }
        }
      end

      before { post '/dois', params: valid_attributes.to_json, headers: headers }

      # it 'creates a Doi' do
      #   expect(json.dig('data', 'attributes', 'doi')).to eq("10.14454/10703")
      #   expect(json.dig('data', 'attributes', 'title')).to eq("")
      #   expect(json.dig('data', 'attributes', 'url')).to eq("http://www.bl.uk/pdf/patspec.pdf")

      #   xml = Maremma.from_xml(Base64.decode64(json.dig('data', 'attributes', 'xml'))).fetch("resource", {})
      #   expect(xml.dig("titles", "title")).to be_nil
      # end

      # it 'returns status code 201' do
      #   expect(response.body).to eq(2)
      #   expect(response).to have_http_status(201)
      # end

      # it 'sets state to registered' do
      #   expect(json.dig('data', 'attributes', 'state')).to eq("registered")
      # end
    end

    context 'when the author changes' do
      let(:author) { [{ "name"=>"Ollomi, Benjamin" }, { "name"=>"Duran, Patrick" }] }
      let(:xml) { Base64.strict_encode64(file_fixture('datacite.xml').read) }
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "doi" => "10.14454/10703",
              "url" => "http://www.bl.uk/pdf/patspec.pdf",
              "xml" => xml,
              "author" => author,
              "event" => "register"
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
        expect(json.dig('data', 'attributes', 'doi')).to eq("10.14454/10703")
        expect(json.dig('data', 'attributes', 'author')).to eq(author)
        expect(json.dig('data', 'attributes', 'url')).to eq("http://www.bl.uk/pdf/patspec.pdf")

        xml = Maremma.from_xml(Base64.decode64(json.dig('data', 'attributes', 'xml'))).fetch("resource", {})
        expect(xml.dig("creators", "creator")).to eq([{"creatorName"=>"Ollomi, Benjamin"}, {"creatorName"=>"Duran, Patrick"}])
      end

      it 'returns status code 201' do
        expect(response).to have_http_status(201)
      end

      it 'sets state to registered' do
        expect(json.dig('data', 'attributes', 'state')).to eq("registered")
      end
    end

    context 'when the author changes no xml' do
      let(:author) { [{ "name"=>"Ollomi, Benjamin" }, { "name"=>"Duran, Patrick" }] }
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "doi" => "10.14454/10703",
              "url" => "http://www.bl.uk/pdf/patspec.pdf",
              "xml" => nil,
              "author" => author,
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

      # it 'creates a Doi' do
      #   expect(json.dig('data', 'attributes', 'doi')).to eq("10.14454/10703")
      #   expect(json.dig('data', 'attributes', 'author')).to eq(author)
      #   expect(json.dig('data', 'attributes', 'url')).to eq("http://www.bl.uk/pdf/patspec.pdf")

      #   xml = Maremma.from_xml(Base64.decode64(json.dig('data', 'attributes', 'xml'))).fetch("resource", {})
      #   expect(xml.dig("creators", "creator")).to eq([{"creatorName"=>"Ollomi, Benjamin"}, {"creatorName"=>"Duran, Patrick"}])
      # end

      # it 'returns status code 201' do
      #   expect(response.body).to eq(2)
      #   expect(response).to have_http_status(201)
      # end

      # it 'sets state to registered' do
      #   expect(json.dig('data', 'attributes', 'state')).to eq("draft")
      # end
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
              "event" => "register"
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
      before { post '/dois', params: not_valid_attributes.to_json, headers: headers }

      it 'returns status code 201' do
        expect(response).to have_http_status(201)
      end

      it 'creates a Doi' do
        expect(json.dig('data', 'attributes', 'doi')).to eq("10.14454/10703")
        expect(json.dig('data', 'attributes', 'title')).to eq("Eating your own Dog Food")
        expect(json.dig('data', 'attributes', 'url')).to eq("http://www.bl.uk/pdf/patspec.pdf")
        expect(json.dig('data', 'attributes', 'author')).to be_blank

        xml = Maremma.from_xml(Base64.decode64(json.dig('data', 'attributes', 'xml'))).fetch("resource", {})
        expect(xml.dig("titles", "title")).to eq("Eating your own Dog Food")
        expect(xml.dig("creators", "creator")).to be_nil
      end
    end

    context 'when the xml is invalid' do
      let(:doi) { create(:doi, client: client, doi: "10.14454/4f6f-zr33") }
      let(:xml) { Base64.strict_encode64(file_fixture('datacite_missing_creator.xml').read) }
      let(:not_valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "doi" => doi.doi,
              "url"=> "http://www.bl.uk/pdf/patspec.pdf",
              "xml" => xml,
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
      before { post '/dois', params: not_valid_attributes.to_json, headers: headers }

      it 'returns status code 422' do
        expect(response).to have_http_status(422)
      end

      it 'returns a validation failure message' do
        expect(json["errors"]).to eq([{"source"=>"creators", "title"=>"Missing child element(s). expected is ( {http://datacite.org/schema/kernel-4}creator ). at line 4, column 0"}])
      end
    end

    describe 'POST /dois/validate' do
      let(:bearer) { User.generate_token(role_id: "client_admin", client_id: client.symbol.downcase) }
      let(:headers) { {'ACCEPT'=>'application/vnd.api+json', 'CONTENT_TYPE'=>'application/vnd.api+json', 'Authorization' => 'Bearer ' + bearer}}

      context 'validates' do
        let(:xml) { ::Base64.strict_encode64(File.read(file_fixture('datacite.xml'))) }
        let(:params) do
          {
            "data" => {
              "type" => "dois",
              "attributes" => {
                "doi" => "10.14454/10703",
                "xml" => xml,
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

        before { post '/dois/validate', params: params.to_json, headers: headers }

        it 'validates a Doi' do
          expect(json.dig('data', 'attributes', 'doi')).to eq("10.14454/10703")
          expect(json.dig('data', 'attributes', 'title')).to eq("Eating your own Dog Food")
          expect(json.dig('data', 'attributes', 'published')).to eq("2016-12-20")
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

        before { post '/dois/validate', params: params.to_json, headers: headers }

        it 'validates a Doi' do
          expect(json.dig('data', 'attributes', 'doi')).to eq("10.14454/10703")
          expect(json.dig('data', 'attributes', 'title')).to eq("Data from: A new malaria agent in African hominids.")
          expect(json.dig('data', 'attributes', 'published')).to eq("2011")
        end

        it 'returns status code 200' do
          expect(response).to have_http_status(200)
        end
      end

      context 'when the creator is missing' do
        let(:xml) { ::Base64.strict_encode64(File.read(file_fixture('datacite_missing_creator.xml'))) }
        let(:params) do
          {
            "data" => {
              "type" => "dois",
              "attributes" => {
                "doi" => "10.14454/10703",
                "xml" => xml,
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

        before { post '/dois/validate', params: params.to_json, headers: headers }

        it 'validates a Doi' do
          expect(json['errors'].size).to eq(1)
          expect(json['errors'].first).to eq("source"=>"creators", "title"=>"Missing child element(s). expected is ( {http://datacite.org/schema/kernel-4}creator ). at line 4, column 0")
        end

        it 'returns status code 200' do
          expect(response).to have_http_status(200)
        end
      end

      context 'when the creator is malformed' do
        let(:xml) { ::Base64.strict_encode64(File.read(file_fixture('datacite_malformed_creator.xml'))) }
        let(:params) do
          {
            "data" => {
              "type" => "dois",
              "attributes" => {
                "doi" => "10.14454/10703",
                "xml" => xml,
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

        before { post '/dois/validate', params: params.to_json, headers: headers }

        it 'validates a Doi' do
          expect(json.dig('data', 'attributes', 'doi')).to eq("10.14454/10703")
          expect(json.dig('data', 'attributes', 'title')).to eq("Eating your own Dog Food")
          expect(json.dig('data', 'attributes', 'published')).to eq("2016-12-20")
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

        before { post '/dois/validate', params: params.to_json, headers: headers }

        it 'validates a Doi' do
          expect(json.dig('data', 'attributes', 'doi')).to eq("10.14454/10703")
          expect(json.dig('data', 'attributes', 'title')).to eq("R Interface to the DataONE REST API")
          expect(json.dig('data', 'attributes', 'published')).to eq("2016-05-27")
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

        before { post '/dois/validate', params: params.to_json, headers: headers }

        it 'validates a Doi' do
          expect(json.dig('data', 'attributes', 'doi')).to eq("10.14454/10703")
          expect(json.dig('data', 'attributes', 'title')).to eq("Analysis Tools for Crossover Experiment of UI using Choice Architecture")
          expect(json.dig('data', 'attributes', 'published')).to eq("2016-03-27")
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

        before { post '/dois/validate', params: params.to_json, headers: headers }

        it 'validates a Doi' do
          expect(json.dig('data', 'attributes', 'doi')).to eq("10.14454/10703")
          expect(json.dig('data', 'attributes', 'title')).to eq("Automated quantitative histology reveals vascular morphodynamics during Arabidopsis hypocotyl secondary growth")
          expect(json.dig('data', 'attributes', 'published')).to eq("2014")
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
                "xml" => xml,
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

        before { post '/dois/validate', params: params.to_json, headers: headers }

        it 'validates a Doi' do
          expect(json.dig('data', 'attributes', 'doi')).to eq("10.14454/10703")
          expect(json.dig('data', 'attributes', 'title')).to eq("Automated quantitative histology reveals vascular morphodynamics during Arabidopsis hypocotyl secondary growth")
          expect(json.dig('data', 'attributes', 'published')).to eq("2014")
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

        before { post '/dois/validate', params: params.to_json, headers: headers }

        it 'validates a Doi' do
          expect(json.dig('data', 'attributes', 'doi')).to eq("10.14454/10703")
          expect(json.dig('data', 'attributes', 'title')).to eq("Triose Phosphate Isomerase Deficiency Is Caused by Altered Dimerization–Not Catalytic Inactivity–of the Mutant Enzymes")
          expect(json.dig('data', 'attributes', 'published')).to eq("2006-12-20")
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

        before { post '/dois/validate', params: params.to_json, headers: headers }

        it 'validates a Doi' do
          expect(json.dig('data', 'attributes', 'doi')).to eq("10.14454/10703")
          expect(json.dig('data', 'attributes', 'title')).to eq("Eating your own Dog Food")
          expect(json.dig('data', 'attributes', 'published')).to eq("2016-12-20")
        end

        it 'returns status code 200' do
          expect(response).to have_http_status(200)
        end
      end
    end

    context 'landing page' do
      let(:url) { "https://blog.datacite.org/re3data-science-europe/" }
      let(:xml) { "PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiPz48cmVzb3VyY2UgeG1sbnM6eHNpPSJodHRwOi8vd3d3LnczLm9yZy8yMDAxL1hNTFNjaGVtYS1pbnN0YW5jZSIgeG1sbnM9Imh0dHA6Ly9kYXRhY2l0ZS5vcmcvc2NoZW1hL2tlcm5lbC00IiB4c2k6c2NoZW1hTG9jYXRpb249Imh0dHA6Ly9kYXRhY2l0ZS5vcmcvc2NoZW1hL2tlcm5lbC00IGh0dHA6Ly9zY2hlbWEuZGF0YWNpdGUub3JnL21ldGEva2VybmVsLTQvbWV0YWRhdGEueHNkIj48aWRlbnRpZmllciBpZGVudGlmaWVyVHlwZT0iRE9JIj4xMC4yNTQ5OS94dWRhMnB6cmFocm9lcXBlZnZucTV6dDZkYzwvaWRlbnRpZmllcj48Y3JlYXRvcnM+PGNyZWF0b3I+PGNyZWF0b3JOYW1lPklhbiBQYXJyeTwvY3JlYXRvck5hbWU+PG5hbWVJZGVudGlmaWVyIHNjaGVtZVVSST0iaHR0cDovL29yY2lkLm9yZy8iIG5hbWVJZGVudGlmaWVyU2NoZW1lPSJPUkNJRCI+MDAwMC0wMDAxLTYyMDItNTEzWDwvbmFtZUlkZW50aWZpZXI+PC9jcmVhdG9yPjwvY3JlYXRvcnM+PHRpdGxlcz48dGl0bGU+U3VibWl0dGVkIGNoZW1pY2FsIGRhdGEgZm9yIEluQ2hJS2V5PVlBUFFCWFFZTEpSWFNBLVVIRkZGQU9ZU0EtTjwvdGl0bGU+PC90aXRsZXM+PHB1Ymxpc2hlcj5Sb3lhbCBTb2NpZXR5IG9mIENoZW1pc3RyeTwvcHVibGlzaGVyPjxwdWJsaWNhdGlvblllYXI+MjAxNzwvcHVibGljYXRpb25ZZWFyPjxyZXNvdXJjZVR5cGUgcmVzb3VyY2VUeXBlR2VuZXJhbD0iRGF0YXNldCI+U3Vic3RhbmNlPC9yZXNvdXJjZVR5cGU+PHJpZ2h0c0xpc3Q+PHJpZ2h0cyByaWdodHNVUkk9Imh0dHBzOi8vY3JlYXRpdmVjb21tb25zLm9yZy9zaGFyZS15b3VyLXdvcmsvcHVibGljLWRvbWFpbi9jYzAvIj5ObyBSaWdodHMgUmVzZXJ2ZWQ8L3JpZ2h0cz48L3JpZ2h0c0xpc3Q+PC9yZXNvdXJjZT4=" }
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "doi" => "10.14454/10703",
              "url" => url,
              "xml" => xml,
              "last-landing-page" => url,
              "last-landing-page-status" => 200,
              "last-landing-page-status-check" => Time.zone.now,
              "last-landing-page-content-type" => "text/html",
              "event" => "register"
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
        expect(json.dig('data', 'attributes', 'url')).to eq(url)
        expect(json.dig('data', 'attributes', 'doi')).to eq("10.14454/10703")
        expect(json.dig('data', 'attributes', 'landing-page', 'status')).to eq(200)
      end

      it 'returns status code 201' do
        expect(response).to have_http_status(201)
      end

      it 'sets state to registered' do
        expect(json.dig('data', 'attributes', 'state')).to eq("registered")
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
    let(:doi) { create(:doi, client: client, doi: "10.5438/8syz-ym47", event: "publish") }

    before { get "/dois/#{doi.doi}/get-url", headers: headers }

    it 'returns url' do
      expect(json["url"]).to eq("https://blog.datacite.org/welcome-helena-cousijn/")
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
    let(:doi) { create(:doi, client: other_client, doi: "10.5438/8syz-ym47", event: "publish") }
    
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
    let(:doi) { create(:doi, client: client, doi: "10.14454/61y1-e521", event: "start") }

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

    it 'returns not DataCite DOI' do
      expect(json['url']).to eq("http://dx.plos.org/10.1371/journal.pbio.2001414")
    end

    it 'returns status code 200' do
      expect(response).to have_http_status(200)
    end
  end

  describe 'GET /dois/get-dois', vcr: true do
    let(:prefix) { create(:prefix, prefix: "10.14454") }
    let!(:client_prefix) { create(:client_prefix, prefix: prefix, client: client) }

    before { get "/dois/get-dois", headers: headers }

    it 'returns all dois' do
      expect(json["dois"].length).to eq(7)
      expect(json["dois"].first).to eq("10.14454/07243.2013.001")
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
