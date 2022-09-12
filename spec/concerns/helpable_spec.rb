# frozen_string_literal: true

require "rails_helper"

describe Doi, vcr: true do
  subject { create(:doi) }

  context "generate_random_provider_symbol" do
    it "should generate" do
      expect(subject.generate_random_provider_symbol).to match(/\A[A-Z]{4}\Z/)
    end
  end

  context "generate_random_repository_symbol" do
    it "should generate" do
      expect(subject.generate_random_repository_symbol).to match(/\A[A-Z]{6}\Z/)
    end
  end

  context "validate_prefix" do
    it "should validate" do
      str = "10.14454"
      expect(subject.validate_prefix(str)).to eq("10.14454")
    end

    it "should validate with slash" do
      str = "10.14454/"
      expect(subject.validate_prefix(str)).to eq("10.14454")
    end

    it "should validate with shoulder" do
      str = "10.14454/FK2"
      expect(subject.validate_prefix(str)).to eq("10.14454")
    end

    it "should not validate if not DOI prefix" do
      str = "20.14454"
      expect(subject.validate_prefix(str)).to be_nil
    end
  end

  context "generate_random_dois" do
    it "should generate" do
      str = "10.14454"
      expect(subject.generate_random_dois(str).first.length).to eq(18)
    end

    it "should generate multiple" do
      str = "10.14454"
      size = 10
      dois = subject.generate_random_dois(str, size: size)
      expect(dois.length).to eq(10)
      expect(dois.first).to start_with("10.14454")
    end

    it "should generate with seed" do
      str = "10.14454"
      number = 123_456
      expect(subject.generate_random_dois(str, number: number)).to eq(
        %w[10.14454/003r-j076],
      )
    end

    it "should generate with seed checksum" do
      str = "10.14454"
      number = 1_234_578
      expect(subject.generate_random_dois(str, number: number)).to eq(
        %w[10.14454/015n-mj18],
      )
    end

    it "should generate with another seed checksum" do
      str = "10.14454"
      number = 1_234_579
      expect(subject.generate_random_dois(str, number: number)).to eq(
        %w[10.14454/015n-mk15],
      )
    end

    it "should generate with shoulder" do
      str = "10.14454/fk2"
      number = 123_456
      expect(subject.generate_random_dois(str, number: number)).to eq(
        %w[10.14454/fk2-003r-j076],
      )
    end

    it "should not generate if not DOI prefix" do
      str = "20.5438"
      expect { subject.generate_random_dois(str) }.to raise_error(
        IdentifierError,
        "No valid prefix found",
      )
    end
  end

  context "match_url_with_domains" do
    it "url missing" do
      domains = "*"
      expect(subject.match_url_with_domains(domains: domains)).to be false
    end

    it "domain missing" do
      url = "https://blog.datacite.org/bla-bla"
      expect(subject.match_url_with_domains(url: url)).to be false
    end

    it "uses *" do
      domains = "*"
      url = "https://blog.datacite.org/bla-bla"
      expect(
        subject.match_url_with_domains(domains: domains, url: url),
      ).to be true
    end

    it "specific host should be in list" do
      domains = "blog.datacite.org,blog.example.com"
      url = "https://blog.datacite.org/bla-bla"
      expect(
        subject.match_url_with_domains(domains: domains, url: url),
      ).to be true
    end

    it "wildcard host should be in list" do
      domains = "*.datacite.org,blog.example.com"
      url = "https://blog.datacite.org/bla-bla"
      expect(
        subject.match_url_with_domains(domains: domains, url: url),
      ).to be true
    end
  end

  context "register_doi", order: :defined do
    let(:provider) { create(:provider, symbol: "DATACITE") }
    let(:client) do
      create(:client, provider: provider, symbol: ENV["MDS_USERNAME"])
    end

    subject do
      build(
        :doi,
        doi: "10.5438/mcnv-ga6n",
        url: "https://blog.datacite.org/",
        client: client,
        aasm_state: "findable",
      )
    end

    it "should register" do
      expect(subject.register_url.body).to eq(
        "data" => { "responseCode" => 1, "handle" => "10.5438/MCNV-GA6N" },
      )
      expect(subject.minted.iso8601).to be_present

      response = subject.get_url

      expect(response.body.dig("data", "responseCode")).to eq(1)
      expect(response.body.dig("data", "values")).to eq(
        [
          {
            "index" => 1,
            "type" => "URL",
            "data" => {
              "format" => "string", "value" => "https://blog.datacite.org/"
            },
            "ttl" => 86_400,
            "timestamp" => "2020-07-26T08:55:31Z",
          },
        ],
      )
    end

    context "https to http" do
      it "should convert" do
        url = "https://orcid.org/0000-0003-1419-2405"
        expect(subject.https_to_http(url)).to eq(
          "http://orcid.org/0000-0003-1419-2405",
        )
      end

      it "should ignore http" do
        url = "http://orcid.org/0000-0003-1419-2405"
        expect(subject.https_to_http(url)).to eq(url)
      end
    end

    # it 'should register on save' do
    #   url = "https://blog.datacite.org/"
    #   subject = create(:doi, doi: "10.5438/hpc4-5t22", url: url, client: client, aasm_state: "findable")

    #   expect(subject.url).to eq(url)
    #   expect(subject.minted.iso8601).to be_present

    #   sleep 1
    #   response = subject.get_url

    #   expect(response.body.dig("data", "responseCode")).to eq(1)
    #   expect(response.body.dig("data", "values")).to eq([{"index"=>1, "type"=>"URL", "data"=>{"format"=>"string", "value"=>"https://blog.datacite.org/"}, "ttl"=>86400, "timestamp"=>"2018-07-24T10:43:28Z"}])
    # end

    it "should change url" do
      subject.url = "https://blog.datacite.org/re3data-science-europe/"
      expect(subject.register_url.body).to eq(
        "data" => { "responseCode" => 1, "handle" => "10.5438/MCNV-GA6N" },
      )
      expect(subject.minted.iso8601).to be_present

      response = subject.get_url

      expect(response.body.dig("data", "responseCode")).to eq(1)
      expect(response.body.dig("data", "values")).to eq(
        [
          {
            "index" => 1,
            "type" => "URL",
            "data" => {
              "format" => "string",
              "value" => "https://blog.datacite.org/re3data-science-europe/",
            },
            "ttl" => 86_400,
            "timestamp" => "2020-07-26T08:55:35Z",
          },
        ],
      )
    end

    it "draft doi" do
      subject =
        build(
          :doi,
          doi: "10.5438/mcnv-ga6n",
          url: "https://blog.datacite.org/",
          client: client,
          aasm_state: "draft",
        )
      expect { subject.register_url }.to raise_error(
        ActionController::BadRequest,
        "DOI is not registered or findable.",
      )
    end

    it "missing username" do
      subject =
        build(
          :doi,
          doi: "10.5438/mcnv-ga6n",
          url: "https://blog.datacite.org/re3data-science-europe/",
          client: nil,
          aasm_state: "findable",
        )
      expect { subject.register_url }.to raise_error(
        ActionController::BadRequest,
        "[Handle] Error updating DOI 10.5438/MCNV-GA6N: client ID missing.",
      )
    end

    it "server not responsible" do
      subject =
        build(
          :doi,
          doi: "10.1371/journal.pbio.2001414",
          url:
            "https://journals.plos.org/plosbiology/article?id=10.1371/journal.pbio.2001414",
          client: client,
          aasm_state: "findable",
        )
      expect(subject.register_url.body).to eq(
        "errors" => [
          {
            "status" => 400,
            "title" => {
              "responseCode" => 301,
              "message" => "That prefix doesn't live here",
              "handle" => "10.1371/JOURNAL.PBIO.2001414",
            },
          },
        ],
      )
      # expect { subject.register_url }.to raise_error(ActionController::BadRequest, "No valid prefix found")
    end
  end

  context "get_dois" do
    let(:provider) { create(:provider, symbol: "DATACITE") }
    let(:client) do
      create(
        :client,
        provider: provider,
        password_input: ENV["MDS_PASSWORD"]
      )
    end

    it "should get dois" do
      options = {
        prefix: "10.5438",
        username: client.symbol,
        password: client.password,
        role_id: "client_admin",
      }
      dois = Doi.get_dois(options)
      expect(dois.length).to eq(446)
      expect(dois.first).to eq("10.5438/0000-00SS")
    end

    it "should handle zero dois" do
      options = {
        prefix: "10.70001",
        username: client.symbol,
        password: client.password,
        role_id: "client_admin",
      }
      dois = Doi.get_dois(options)
      expect(dois.length).to eq(0)
    end
  end
end
