require 'rails_helper'

describe "content_negotation", type: :request do
  let(:provider) { create(:provider, symbol: "DATACITE") }
  let(:client) { create(:client, provider: provider, symbol: ENV['MDS_USERNAME'], password: ENV['MDS_PASSWORD']) }
  let(:bearer) { Client.generate_token(role_id: "client_admin", uid: client.symbol, provider_id: provider.symbol.downcase, client_id: client.symbol.downcase, password: client.password) }
  let(:doi) { create(:doi, client: client, aasm_state: "findable") }

  context "no permission" do
    let(:doi) { create(:doi) }

    before { get "/#{doi.doi}", headers: { "HTTP_ACCEPT" => "application/vnd.jats+xml", 'Authorization' => 'Bearer ' + bearer } }

    it 'returns error message' do
      expect(json["errors"]).to eq([{"status"=>"403", "title"=>"You are not authorized to access this resource."}])
    end

    it 'returns status code 403' do
      expect(response).to have_http_status(403)
    end
  end

  context "no authentication" do
    let(:doi) { create(:doi) }  
    before { get "/#{doi.doi}", headers: { "HTTP_ACCEPT" => "application/vnd.jats+xml" } }

    it 'returns error message' do
      expect(json["errors"]).to eq([{"status"=>"401", "title"=>"Bad credentials."}])
    end

    it 'returns status code 401' do
      expect(response).to have_http_status(401)
    end
  end

  context "application/vnd.jats+xml" do
    before { get "/#{doi.doi}", headers: { "HTTP_ACCEPT" => "application/vnd.jats+xml", 'Authorization' => 'Bearer ' + bearer } }

    it 'returns the Doi' do
      jats = Maremma.from_xml(response.body).fetch("element_citation", {})
      expect(jats.dig("publication_type")).to eq("data")
      expect(jats.dig("data_title")).to eq("Data from: A new malaria agent in African hominids.")
    end

    it 'returns status code 200' do
      expect(response).to have_http_status(200)
    end
  end

  context "application/vnd.jats+xml link" do
    before { get "/application/vnd.jats+xml/#{doi.doi}" }

    it 'returns the Doi' do
      jats = Maremma.from_xml(response.body).fetch("element_citation", {})
      expect(jats.dig("publication_type")).to eq("data")
      expect(jats.dig("data_title")).to eq("Data from: A new malaria agent in African hominids.")
    end

    it 'returns status code 200' do
      expect(response).to have_http_status(200)
    end
  end

  context "application/vnd.datacite.datacite+xml" do
    before { get "/#{doi.doi}", headers: { "HTTP_ACCEPT" => "application/vnd.datacite.datacite+xml", 'Authorization' => 'Bearer ' + bearer  } }

    it 'returns the Doi' do
      data = Maremma.from_xml(response.body).to_h.fetch("resource", {})
      expect(data.dig("xmlns")).to eq("http://datacite.org/schema/kernel-4")
      expect(data.dig("publisher")).to eq("Dryad Digital Repository")
      expect(data.dig("titles", "title")).to eq("Data from: A new malaria agent in African hominids.")
    end

    it 'returns status code 200' do
      expect(response).to have_http_status(200)
    end
  end

  context "application/vnd.datacite.datacite+xml link" do
    before { get "/application/vnd.datacite.datacite+xml/#{doi.doi}" }

    it 'returns the Doi' do
      data = Maremma.from_xml(response.body).to_h.fetch("resource", {})
      expect(data.dig("xmlns")).to eq("http://datacite.org/schema/kernel-4")
      expect(data.dig("publisher")).to eq("Dryad Digital Repository")
      expect(data.dig("titles", "title")).to eq("Data from: A new malaria agent in African hominids.")
    end

    it 'returns status code 200' do
      expect(response).to have_http_status(200)
    end
  end

  context "application/vnd.datacite.datacite+xml schema 3" do
    let(:xml) { file_fixture('datacite_schema_3.xml').read }
    let(:doi) { create(:doi, xml: xml, client: client, regenerate: false) }

    before { get "/#{doi.doi}", headers: { "HTTP_ACCEPT" => "application/vnd.datacite.datacite+xml", 'Authorization' => 'Bearer ' + bearer  } }

    it 'returns the Doi' do
      data = Maremma.from_xml(response.body).to_h.fetch("resource", {})
      expect(data.dig("xmlns")).to eq("http://datacite.org/schema/kernel-3")
      expect(data.dig("publisher")).to eq("Dryad Digital Repository")
      expect(data.dig("titles", "title")).to eq("Data from: A new malaria agent in African hominids.")
    end

    it 'returns status code 200' do
      expect(response).to have_http_status(200)
    end
  end

  # context "no metadata" do
  #   let(:doi) { create(:doi, xml: nil, client: client) }

  #   before { get "/#{doi.doi}", headers: { "HTTP_ACCEPT" => "application/vnd.datacite.datacite+xml", 'Authorization' => 'Bearer ' + bearer  } }

  #   it 'returns the Doi' do
  #     expect(response.body).to eq('')
  #   end

  #   it 'returns status code 200' do
  #     expect(response).to have_http_status(200)
  #   end
  # end

  context "application/vnd.datacite.datacite+xml not found" do
    before { get "/xxx", headers: { "HTTP_ACCEPT" => "application/vnd.datacite.datacite+xml", 'Authorization' => 'Bearer ' + bearer  } }

    it 'returns error message' do
      expect(json["errors"]).to eq([{"status"=>"404", "title"=>"The resource you are looking for doesn't exist."}])
    end

    it 'returns status code 404' do
      expect(response).to have_http_status(404)
    end
  end

  context "application/vnd.datacite.datacite+json" do
    before { get "/#{doi.doi}", headers: { "HTTP_ACCEPT" => "application/vnd.datacite.datacite+json", 'Authorization' => 'Bearer ' + bearer  } }

    it 'returns the Doi' do
      expect(json["doi"]).to eq(doi.doi)
    end

    it 'returns status code 200' do
      expect(response).to have_http_status(200)
    end
  end

  context "application/vnd.datacite.datacite+json link" do
    before { get "/application/vnd.datacite.datacite+json/#{doi.doi}" }

    it 'returns the Doi' do
      expect(json["doi"]).to eq(doi.doi)
    end

    it 'returns status code 200' do
      expect(response).to have_http_status(200)
    end
  end

  context "application/vnd.crosscite.crosscite+json" do
    before { get "/#{doi.doi}", headers: { "HTTP_ACCEPT" => "application/vnd.crosscite.crosscite+json", 'Authorization' => 'Bearer ' + bearer  } }

    it 'returns the Doi' do
      expect(json["doi"]).to eq(doi.doi)
    end

    it 'returns status code 200' do
      expect(response).to have_http_status(200)
    end
  end

  context "application/vnd.crosscite.crosscite+json link" do
    before { get "/application/vnd.crosscite.crosscite+json/#{doi.doi}" }

    it 'returns the Doi' do
      expect(json["doi"]).to eq(doi.doi)
    end

    it 'returns status code 200' do
      expect(response).to have_http_status(200)
    end
  end

  context "application/vnd.schemaorg.ld+json" do
    before { get "/#{doi.doi}", headers: { "HTTP_ACCEPT" => "application/vnd.schemaorg.ld+json", 'Authorization' => 'Bearer ' + bearer  } }

    it 'returns the Doi' do
      expect(json["@type"]).to eq("Dataset")
    end

    it 'returns status code 200' do
      expect(response).to have_http_status(200)
    end
  end

  context "application/vnd.schemaorg.ld+json link" do
    before { get "/application/vnd.schemaorg.ld+json/#{doi.doi}" }

    it 'returns the Doi' do
      expect(json["@type"]).to eq("Dataset")
    end

    it 'returns status code 200' do
      expect(response).to have_http_status(200)
    end
  end

  context "application/vnd.citationstyles.csl+json" do
    before { get "/#{doi.doi}", headers: { "HTTP_ACCEPT" => "application/vnd.citationstyles.csl+json", 'Authorization' => 'Bearer ' + bearer  } }

    it 'returns the Doi' do
      expect(json["type"]).to eq("dataset")
    end

    it 'returns status code 200' do
      expect(response).to have_http_status(200)
    end
  end

  context "application/vnd.citationstyles.csl+json link" do
    before { get "/application/vnd.citationstyles.csl+json/#{doi.doi}" }

    it 'returns the Doi' do
      expect(json["type"]).to eq("dataset")
    end

    it 'returns status code 200' do
      expect(response).to have_http_status(200)
    end
  end

  context "application/x-research-info-systems" do
    before { get "/#{doi.doi}", headers: { "HTTP_ACCEPT" => "application/x-research-info-systems", 'Authorization' => 'Bearer ' + bearer  } }

    it 'returns the Doi' do
      expect(response.body).to start_with("TY  - DATA")
    end

    it 'returns status code 200' do
      expect(response).to have_http_status(200)
    end
  end

  context "application/x-research-info-systems link" do
    before { get "/application/x-research-info-systems/#{doi.doi}" }

    it 'returns the Doi' do
      expect(response.body).to start_with("TY  - DATA")
    end

    it 'returns status code 200' do
      expect(response).to have_http_status(200)
    end
  end

  context "application/x-bibtex" do
    before { get "/#{doi.doi}", headers: { "HTTP_ACCEPT" => "application/x-bibtex", 'Authorization' => 'Bearer ' + bearer  } }

    it 'returns the Doi' do
      expect(response.body).to start_with("@misc{https://handle.test.datacite.org/#{doi.doi.downcase}")
    end

    it 'returns status code 200' do
      expect(response).to have_http_status(200)
    end
  end

  context "application/x-bibtex link" do
    before { get "/application/x-bibtex/#{doi.doi}" }

    it 'returns the Doi' do
      expect(response.body).to start_with("@misc{https://handle.test.datacite.org/#{doi.doi.downcase}")
    end

    it 'returns status code 200' do
      expect(response).to have_http_status(200)
    end
  end

  context "text/x-bibliography", vcr: true do
    context "default style" do
      before { get "/#{doi.doi}", headers: { "HTTP_ACCEPT" => "text/x-bibliography", 'Authorization' => 'Bearer ' + bearer  } }

      it 'returns the Doi' do
        expect(response.body).to start_with("Ollomo, B.")
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end
    end

    context "default style link" do
      before { get "/text/x-bibliography/#{doi.doi}" }

      it 'returns the Doi' do
        expect(response.body).to start_with("Ollomo, B.")
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end
    end

    context "ieee style" do
      before { get "/#{doi.doi}?style=ieee", headers: { "HTTP_ACCEPT" => "text/x-bibliography", 'Authorization' => 'Bearer ' + bearer  } }

      it 'returns the Doi' do
        expect(response.body).to start_with("B. Ollomo")
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end
    end

    context "ieee style link" do      
      before { get "/text/x-bibliography/#{doi.doi}?style=ieee" }

      it 'returns the Doi' do
        expect(response.body).to start_with("B. Ollomo")
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end
    end

    context "style and locale" do
      before { get "/#{doi.doi}?style=vancouver&locale=de", headers: { "HTTP_ACCEPT" => "text/x-bibliography", 'Authorization' => 'Bearer ' + bearer  } }

      it 'returns the Doi' do
        expect(response.body).to start_with("Ollomo B")
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end
    end
  end

  context "unknown content type" do
    before { get "/#{doi.doi}", headers: { "HTTP_ACCEPT" => "text/csv", 'Authorization' => 'Bearer ' + bearer  } }

    it 'returns the Doi' do
      expect(json["errors"]).to eq([{"status"=>"406", "title"=>"The content type is not recognized."}])
    end

    it 'returns status code 406' do
      expect(response).to have_http_status(406)
    end
  end

  context "missing content type" do
    before { get "/#{doi.doi}", headers: { 'Authorization' => 'Bearer ' + bearer  } }

    it 'returns the Doi' do
      expect(json["errors"]).to eq([{"status"=>"406", "title"=>"The content type is not recognized."}])
    end

    it 'returns status code 406' do
      expect(response).to have_http_status(406)
    end
  end
end
