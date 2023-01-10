# frozen_string_literal: true

require "rails_helper"

describe "Providers", type: :controller, elasticsearch: true do
  subject { ProvidersController.new }
  before(:all) do
    current_year = Date.today.year
    @CUMULTATIVE_BY_YEAR = (2015..current_year).to_a.map do |year|
      { "count" => 3, "id" => "#{year}", "title" => "#{year}" }
    end
    @CUMULTATIVE_BY_YEAR_WITH_DELETES = (2015..2017).to_a.map do |year|
      { "count" => 2, "id" => "#{year}", "title" => "#{year}" }
    end | (2018..current_year).to_a.map do |year|
      { "count" => 1, "id" => "#{year}", "title" => "#{year}" }
    end
  end

  describe "provider_count" do
    before do
      allow(Time.zone).to receive(:now).and_return(Time.mktime(2_015, 4, 8))
      @providers = create_list(:provider, 3)
    end

    it "counts all providers" do
      Provider.import
      sleep 2
      expect(subject.provider_count).to match_array(
        @CUMULTATIVE_BY_YEAR
      )
    end

    it "takes into account deleted providers" do
      @providers.first.update(deleted_at: "2018-06-14")
      @providers.last.update(deleted_at: "2015-06-14")
      Provider.import
      sleep 2
      expect(subject.provider_count).to match_array(
        @CUMULTATIVE_BY_YEAR_WITH_DELETES
      )
    end
  end

  describe "client_count" do
    before do
      allow(Time.zone).to receive(:now).and_return(Time.mktime(2_015, 4, 8))
      @clients = create_list(:client, 3)
    end

    it "counts all clients" do
      Client.import
      sleep 2
      expect(subject.client_count).to match_array(
        @CUMULTATIVE_BY_YEAR
      )
    end

    it "takes into account deleted clients" do
      @clients.first.update(deleted_at: "2018-06-14")
      @clients.last.update(deleted_at: "2015-06-14")
      Client.import
      sleep 2
      expect(subject.client_count).to match_array(
        @CUMULTATIVE_BY_YEAR_WITH_DELETES
      )
    end
  end

  describe "doi_count" do
    before do
      allow(Time.zone).to receive(:now).and_return(Time.mktime(2_015, 4, 8))
    end

    let(:consortium) do
      create(:provider, role_name: "ROLE_CONSORTIUM", symbol: "DC")
    end
    let(:provider) do
      create(
        :provider,
        consortium: consortium,
        role_name: "ROLE_CONSORTIUM_ORGANIZATION",
        symbol: "DATACITE",
      )
    end
    let(:client) do
      create(:client, provider: provider, symbol: "DATACITE.TEST")
    end
    let!(:datacite_dois) do
      create_list(
        :doi,
        3,
        client: client, aasm_state: "findable", type: "DataciteDoi",
      )
    end
    let!(:datacite_doi) { create(:doi, type: "DataciteDoi") }

    it "counts all dois" do
      DataciteDoi.import
      sleep 2

      expect(subject.doi_count).to eq(
        [{ "count" => 4, "id" => "2015", "title" => "2015" }],
      )
    end

    it "counts all consortium dois" do
      DataciteDoi.import
      sleep 2

      expect(subject.doi_count(consortium_id: "dc")).to eq(
        [{ "count" => 3, "id" => "2015", "title" => "2015" }],
      )
    end

    it "counts all consortium dois no dois" do
      DataciteDoi.import
      sleep 2

      expect(subject.doi_count(consortium_id: "abc")).to eq([])
    end

    it "counts all provider dois" do
      DataciteDoi.import
      sleep 2

      expect(subject.doi_count(provider_id: "datacite")).to eq(
        [{ "count" => 3, "id" => "2015", "title" => "2015" }],
      )
    end

    it "counts all provider dois no dois" do
      DataciteDoi.import
      sleep 2

      expect(subject.doi_count(provider_id: "abc")).to eq([])
    end

    it "counts all client dois" do
      DataciteDoi.import
      sleep 2

      expect(subject.doi_count(client_id: "datacite.test")).to eq(
        [{ "count" => 3, "id" => "2015", "title" => "2015" }],
      )
    end

    it "counts all client dois no dois" do
      DataciteDoi.import
      sleep 2

      expect(subject.doi_count(client_id: "abc")).to eq([])
    end
  end
end
