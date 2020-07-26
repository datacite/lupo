require "rails_helper"

describe "Providers", type: :controller, elasticsearch: true do
  subject { ProvidersController.new }

  describe "provider_count" do
    before do
      allow(Time.zone).to receive(:now).and_return(Time.mktime(2015, 4, 8))
      @providers = create_list(:provider, 3)
    end
  
    it "counts all providers" do
      Provider.import
      sleep 2
      expect(subject.provider_count).to eq([{"count"=>3, "id"=>"2015", "title"=>"2015"},
        {"count"=>3, "id"=>"2016", "title"=>"2016"},
        {"count"=>3, "id"=>"2017", "title"=>"2017"},
        {"count"=>3, "id"=>"2018", "title"=>"2018"},
        {"count"=>3, "id"=>"2019", "title"=>"2019"},
        {"count"=>3, "id"=>"2020", "title"=>"2020"}])
    end

    it "takes into account deleted providers" do
      @providers.first.update(deleted_at: "2018-06-14")
      @providers.last.update(deleted_at: "2015-06-14")
      Provider.import
      sleep 2
      expect(subject.provider_count).to eq([{"count"=>1, "id"=>"2018", "title"=>"2018"},
        {"count"=>1, "id"=>"2019", "title"=>"2019"},
        {"count"=>1, "id"=>"2020", "title"=>"2020"},
        {"count"=>2, "id"=>"2015", "title"=>"2015"},
        {"count"=>2, "id"=>"2016", "title"=>"2016"},
        {"count"=>2, "id"=>"2017", "title"=>"2017"}])
    end
  end

  describe "client_count" do
    before do
      allow(Time.zone).to receive(:now).and_return(Time.mktime(2015, 4, 8))
      @clients = create_list(:client, 3)
    end
  
    it "counts all clients" do
      Client.import
      sleep 2
      expect(subject.client_count).to eq([{"count"=>3, "id"=>"2015", "title"=>"2015"},
        {"count"=>3, "id"=>"2016", "title"=>"2016"},
        {"count"=>3, "id"=>"2017", "title"=>"2017"},
        {"count"=>3, "id"=>"2018", "title"=>"2018"},
        {"count"=>3, "id"=>"2019", "title"=>"2019"},
        {"count"=>3, "id"=>"2020", "title"=>"2020"}])
    end

    it "takes into account deleted clients" do
      @clients.first.update(deleted_at: "2018-06-14")
      @clients.last.update(deleted_at: "2015-06-14")
      Client.import
      sleep 2
      expect(subject.client_count).to eq([{"count"=>1, "id"=>"2018", "title"=>"2018"},
        {"count"=>1, "id"=>"2019", "title"=>"2019"},
        {"count"=>1, "id"=>"2020", "title"=>"2020"},
        {"count"=>2, "id"=>"2015", "title"=>"2015"},
        {"count"=>2, "id"=>"2016", "title"=>"2016"},
        {"count"=>2, "id"=>"2017", "title"=>"2017"}])
    end
  end

  describe "doi_count" do
    before do
      allow(Time.zone).to receive(:now).and_return(Time.mktime(2015, 4, 8))
    end

    let(:consortium) { create(:provider, role_name: "ROLE_CONSORTIUM", symbol: "DC") }
    let(:provider) { create(:provider, consortium: consortium, role_name: "ROLE_CONSORTIUM_ORGANIZATION", symbol: "DATACITE") }
    let(:client) { create(:client, provider: provider, symbol: "DATACITE.TEST") }
    let!(:dois) { create_list(:doi, 3, client: client, aasm_state: "findable", type: "DataciteDoi") }
    let!(:doi) { create(:doi, type: "DataciteDoi") }

    it "counts all dois" do
      DataciteDoi.import
      sleep 2

      expect(subject.doi_count).to eq([{"count"=>4, "id"=>"2015", "title"=>"2015"}])
    end

    it "counts all consortium dois" do
      DataciteDoi.import
      sleep 2

      expect(subject.doi_count(consortium_id: "dc")).to eq([{"count"=>3, "id"=>"2015", "title"=>"2015"}])
    end

    it "counts all consortium dois no dois" do
      DataciteDoi.import
      sleep 2

      expect(subject.doi_count(consortium_id: "abc")).to eq([])
    end

    it "counts all provider dois" do
      DataciteDoi.import
      sleep 2

      expect(subject.doi_count(provider_id: "datacite")).to eq([{"count"=>3, "id"=>"2015", "title"=>"2015"}])
    end

    it "counts all provider dois no dois" do
      DataciteDoi.import
      sleep 2

      expect(subject.doi_count(provider_id: "abc")).to eq([])
    end

    it "counts all client dois" do
      DataciteDoi.import
      sleep 2

      expect(subject.doi_count(client_id: "datacite.test")).to eq([{"count"=>3, "id"=>"2015", "title"=>"2015"}])
    end

    it "counts all client dois no dois" do
      DataciteDoi.import
      sleep 2

      expect(subject.doi_count(client_id: "abc")).to eq([])
    end
  end
end
