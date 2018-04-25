require 'rails_helper'

describe "dois", type: :request do
  let(:provider)  { create(:provider, symbol: "ADMIN") }
  let(:client)  { create(:client, provider: provider) }
  let!(:dois) { create_list(:doi, 3, client: client) }
  let(:doi) { create(:doi, client: client) }
  let(:bearer) { User.generate_token(role_id: "staff_admin") }
  let(:headers) { {'ACCEPT'=>'application/vnd.api+json', 'CONTENT_TYPE'=>'application/vnd.api+json', 'Authorization' => 'Bearer ' + bearer}}

  describe 'GET /dois' do
    before { get '/dois', headers: headers }

    it 'returns dois' do
      expect(json['data'].size).to eq(3)
    end

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
  end

  describe 'PATCH /dois/:id' do
    context 'when the record exists' do
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "doi" => "10.4122/10703",
              "url"=> "http://www.bl.uk/pdf/pat.pdf",
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
        expect(json.dig('data', 'attributes', 'doi')).to eq("10.4122/10703")
        expect(json.dig('data', 'attributes', 'title')).to eq("Referee report. For: RESEARCH-3482 [version 5; referees: 1 approved, 1 approved with reservations]")
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end

      it 'sets state to registered' do
        expect(json.dig('data', 'attributes', 'state')).to eq("registered")
      end
    end

    context 'when the title is changed' do
      let(:title) { "Submitted chemical data for InChIKey=YAPQBXQYLJRXSA-UHFFFAOYSA-N" }
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "doi" => "10.4122/10703",
              "url" => "http://www.bl.uk/pdf/pat.pdf",
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
        expect(json.dig('data', 'attributes', 'doi')).to eq("10.4122/10703")
        expect(json.dig('data', 'attributes', 'title')).to eq(title)
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
    context 'when the request is valid' do
      let(:xml) { Base64.strict_encode64(file_fixture('datacite.xml').read) }
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "doi" => "10.4122/10703",
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
        expect(json.dig('data', 'attributes', 'doi')).to eq("10.4122/10703")
        expect(json.dig('data', 'attributes', 'title')).to eq("Eating your own Dog Food")
        expect(json.dig('data', 'attributes', 'schema-version')).to eq("http://datacite.org/schema/kernel-4")
      end

      it 'returns status code 201' do
        expect(response).to have_http_status(201)
      end

      it 'sets state to registered' do
        expect(json.dig('data', 'attributes', 'state')).to eq("registered")
      end
    end

    context 'when the request uses schema 3' do
      let(:xml) { Base64.strict_encode64(file_fixture('datacite_schema_3.xml').read) }
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "doi" => "10.4122/10703",
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
        expect(json.dig('data', 'attributes', 'doi')).to eq("10.4122/10703")
        expect(json.dig('data', 'attributes', 'title')).to eq("Data from: A new malaria agent in African hominids.")
        expect(json.dig('data', 'attributes', 'schema-version')).to eq("http://datacite.org/schema/kernel-3")
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
              "doi" => "10.4122/10703",
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
        expect(json.dig('data', 'attributes', 'doi')).to eq("10.4122/10703")
        expect(json.dig('data', 'attributes', 'title')).to eq("Referee report. For: RESEARCH-3482 [version 5; referees: 1 approved, 1 approved with reservations]")
        expect(json.dig('data', 'attributes', 'url')).to eq("http://www.bl.uk/pdf/patspec.pdf")
      end

      it 'returns status code 201' do
        expect(response).to have_http_status(201)
      end

      it 'sets state to registered' do
        expect(json.dig('data', 'attributes', 'state')).to eq("registered")
      end
    end

    context 'when the author changes' do
      let(:author) { [{ "name"=>"Ollomi, Benjamin" }, { "name"=>"Duran, Patrick" }] }
      let(:xml) { Base64.strict_encode64(file_fixture('datacite.xml').read) }
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "doi" => "10.4122/10703",
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
        expect(json.dig('data', 'attributes', 'doi')).to eq("10.4122/10703")
        expect(json.dig('data', 'attributes', 'author')).to eq([{ "name"=>"Ollomi, Benjamin" }, { "name"=>"Duran, Patrick" }])
        expect(json.dig('data', 'attributes', 'url')).to eq("http://www.bl.uk/pdf/patspec.pdf")
      end

      it 'returns status code 201' do
        expect(response).to have_http_status(201)
      end

      it 'sets state to registered' do
        expect(json.dig('data', 'attributes', 'state')).to eq("registered")
      end
    end

    context 'state change with test prefix' do
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

      it 'returns status code 422' do
        expect(response).to have_http_status(422)
      end

      it 'returns a validation failure message' do
        expect(json["errors"]).to eq([{"source"=>"doi", "title"=>"Is invalid"}])
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
                "doi" => "10.4122/10703",
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
          expect(json.dig('data', 'attributes', 'doi')).to eq("10.4122/10703")
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
                "doi" => "10.4122/10703",
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
          expect(json.dig('data', 'attributes', 'doi')).to eq("10.4122/10703")
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
                "doi" => "10.4122/10703",
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
          expect(json['errors'].first).to eq("source"=>"resource", "title"=>"No matching global declaration available for the validation root. at line 2, column 0")
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
                "doi" => "10.4122/10703",
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
          expect(json.dig('data', 'attributes', 'doi')).to eq("10.4122/10703")
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
                "doi" => "10.4122/10703",
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
          expect(json.dig('data', 'attributes', 'doi')).to eq("10.4122/10703")
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
                "doi" => "10.4122/10703",
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
          expect(json.dig('data', 'attributes', 'doi')).to eq("10.4122/10703")
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
                "doi" => "10.4122/10703",
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
          expect(json.dig('data', 'attributes', 'doi')).to eq("10.4122/10703")
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
                "doi" => "10.4122/10703",
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
          expect(json.dig('data', 'attributes', 'doi')).to eq("10.4122/10703")
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
                "doi" => "10.4122/10703",
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
          expect(json.dig('data', 'attributes', 'doi')).to eq("10.4122/10703")
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
                "doi" => "10.4122/10703",
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
          expect(json.dig('data', 'attributes', 'doi')).to eq("10.4122/10703")
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
              "doi" => "10.4122/10703",
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
        expect(json.dig('data', 'attributes', 'doi')).to eq("10.4122/10703")
        # expect(json.dig('data', 'attributes', 'landing-page', 'url')).to eq(url)
        # expect(json.dig('data', 'attributes', 'landing-page', 'status')).to eq(200)
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
    before { post '/dois/set-state', headers: headers }

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

    before { post '/dois/set-minted', headers: headers }

    it 'returns dois' do
      expect(json['message']).to eq("DOI minted timestamp added.")
    end

    it 'returns status code 200' do
      expect(response).to have_http_status(200)
    end
  end

  describe 'POST /dois/set-url' do
    let!(:dois) { create_list(:doi, 3, client: client, url: nil) }

    before { post '/dois/set-url', headers: headers }

    it 'returns dois' do
      expect(json['message']).to eq("Adding missing URLs queued.")
    end

    it 'returns status code 200' do
      expect(response).to have_http_status(200)
    end
  end

  describe 'POST /dois/delete-test-dois' do
    before { post '/dois/delete-test-dois', headers: headers }

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
    let(:prefix) { "10.5438" }

    before { get "/dois/random?prefix=#{prefix}", headers: headers }

    it 'returns random doi with prefix' do
      expect(json['doi']).to start_with(prefix)
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
end
