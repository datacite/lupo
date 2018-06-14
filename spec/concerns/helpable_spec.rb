require 'rails_helper'

describe Doi, vcr: true do
  subject { create(:doi) }

  context "validate_prefix" do
    it 'should validate' do
      str = "10.5072"
      expect(subject.validate_prefix(str)).to eq("10.5072")
    end

    it 'should validate with slash' do
      str = "10.5072/"
      expect(subject.validate_prefix(str)).to eq("10.5072")
    end

    it 'should validate with shoulder' do
      str = "10.5072/FK2"
      expect(subject.validate_prefix(str)).to eq("10.5072")
    end

    it 'should not validate if not DOI prefix' do
      str = "20.5072"
      expect(subject.validate_prefix(str)).to be_nil
    end
  end

  context "generate_random_doi" do
    it 'should generate' do
      str = "10.5072"
      expect(subject.generate_random_doi(str).length).to eq(17)
    end

    it 'should generate with seed' do
      str = "10.5072"
      number = 123456
      expect(subject.generate_random_doi(str, number: number)).to eq("10.5072/003r-j076")
    end

    it 'should generate with seed checksum' do
      str = "10.5072"
      number = 1234578
      expect(subject.generate_random_doi(str, number: number)).to eq("10.5072/015n-mj18")
    end

    it 'should generate with another seed checksum' do
      str = "10.5072"
      number = 1234579
      expect(subject.generate_random_doi(str, number: number)).to eq("10.5072/015n-mk15")
    end

    it 'should generate with shoulder' do
      str = "10.5072/fk2"
      number = 123456
      expect(subject.generate_random_doi(str, number: number)).to eq("10.5072/fk2-003r-j076")
    end

    it 'should not generate if not DOI prefix' do
      str = "20.5438"
      expect { subject.generate_random_doi(str) }.to raise_error(IdentifierError, "No valid prefix found")
    end
  end

  context "register_doi", order: :defined do
    let(:provider) { create(:provider, symbol: "DATACITE") }
    let(:client) { create(:client, provider: provider, symbol: ENV['MDS_USERNAME'], password: ENV['MDS_PASSWORD']) }
    
    subject { build(:doi, doi: "10.5438/mcnv-ga6n", client: client, aasm_state: "findable") }

    it 'should register' do
      url = "https://blog.datacite.org/"
      options = { url: url, username: client.symbol, password: client.password, role_id: "client_admin" }
      expect(subject.register_url(options).body).to eq("data"=>"OK")

      expect(subject.get_url(options).body).to eq("data" => url)
    end

    it 'should change url' do
      url = "https://blog.datacite.org/re3data-science-europe/"
      options = { url: url, username: client.symbol, password: client.password, role_id: "client_admin" }
      expect(subject.register_url(options).body).to eq("data"=>"OK")

      expect(subject.get_url(options).body).to eq("data" => url)
    end

    it 'draft doi' do
      subject = build(:doi, doi: "10.5438/mcnv-ga6n", client: client, aasm_state: "draft")
      url = "https://blog.datacite.org/"
      options = { url: url, username: client.symbol, password: client.password, role_id: "client_admin" }
      expect(subject.register_url(options).body).to eq("errors"=>[{"title"=>"DOI is not registered or findable."}])
    end

    it 'missing username and password' do
      options = { url: "https://blog.datacite.org/re3data-science-europe/" }
      expect(subject.register_url(options).body).to eq("errors"=>[{"title"=>"Username or password missing."}])
    end

    it 'wrong username and password' do
      options = { url: "https://blog.datacite.org/re3data-science-europe/", username: client.uid, password: 12345, role_id: "client_admin" }
      expect(subject.register_url(options).body).to eq("errors"=>[{"status"=>401, "title"=>"Unauthorized"}])
    end
  end

  context "get_dois" do
    let(:provider) { create(:provider, symbol: "DATACITE") }
    let(:client) { create(:client, provider: provider, symbol: ENV['MDS_USERNAME'], password: ENV['MDS_PASSWORD']) }
    
    it 'should get dois' do
      options = { username: client.symbol, password: client.password, role_id: "client_admin" }
      dois = Doi.get_dois(options).body["data"].split("\n")
      expect(dois.length).to eq(24)
      expect(dois.first).to eq("10.14454/05MB-Q396")
    end
  end
end
