# frozen_string_literal: true

require "rails_helper"

describe "Facetable", type: :controller do
    let(:author_aggs) { JSON.parse(file_fixture("authors_aggs.json").read) }
    let(:author_aggs_with_multiple_name_identifiers) { JSON.parse(file_fixture("authors_aggs_with_multiple_name_identifiers.json").read) }
    let(:model) { DataciteDoisController.new }
    let(:funder_aggs) { JSON.parse(file_fixture("funders_aggs.json").read) }
    it "facet by author" do
      authors = model.facet_by_authors(author_aggs)

      expected_result = [
        { "id" => "https://orcid.org/0000-0003-1419-2405", "title" => "Fenner, Martin", "count" => 244 },
        { "id" => "https://orcid.org/0000-0001-9570-8121", "title" => "Lambert, Simon", "count" => 23 }
      ]
      expect(authors).to eq (expected_result)
    end

    it "facet by author where author may have multiple nameIdentifiers" do
      authors = model.facet_by_authors(author_aggs_with_multiple_name_identifiers)

      expected_result = [
        {
            "id" => "https://orcid.org/0000-0002-0429-5446",
            "title" => "Nam, Hyung-song",
            "count" => 28,
        },
        {
            "id" => "https://orcid.org/0000-0003-4973-3128",
            "title" => "Casares, Ramón",
            "count" => 12,
        },
        {
            "id" => "https://orcid.org/0000-0002-3776-4755",
            "title" => "Gomeseria, Ronald",
            "count" => 4,
        },
        {
            "id" => "https://orcid.org/0000-0002-6014-2161",
            "title" => "Kartha, Sivan",
            "count" => 4,
        },
        {
            "id" => "https://orcid.org/0000-0003-1026-5865",
            "title" => "Willemen, Louise",
            "count" => 4,
        },
        {
            "id" => "https://orcid.org/0000-0003-4624-488X",
            "title" => "Schwarz, Nina",
            "count" => 4,
        },
        {
            "id" => "https://orcid.org/0000-0002-2149-9897",
            "title" => "A, Subaveerapandiyan",
            "count" => 3,
        },
        {
            "id" => "https://orcid.org/0000-0002-4541-7294",
            "title" => "Puntiroli, Michael",
            "count" => 3,
        },
        ]
      expect(authors).to eq (expected_result)
    end

    it "facet by funder" do
      funders = model.facet_by_funders(funder_aggs)

      expected_result = [
        {"count"=>5, "id"=>"https://ror.org/00cvxb145", "title"=>"Gift to the University of Washington College of the Environment (from the Seeley family)"},
        {"count"=>5, "id"=>"https://ror.org/021nxhr62", "title"=>"National Science Foundation (NSF)"},
        {"count"=>5, "id"=>"https://ror.org/04p8xrf95", "title"=>"Tetiaroa Society"},
        {"count"=>2, "id"=>"https://ror.org/04tqhj682", "title"=>"The French ministry of the Army, the French ministry of Ecological Transition,  the French Office for Biodiversity (OFB), the French Development Agency (AFD) and Météo France"},
        {"count"=>1, "id"=>"https://doi.org/10.13039/100000001", "title"=>"National Science Foundation "},
        {"count"=>1, "id"=>"https://ror.org/0040r6f76", "title"=>"Victoria University of Wellington"},
        {"count"=>1, "id"=>"https://ror.org/0128rbw31", "title"=>"AAUS"},
        {"count"=>1, "id"=>"https://ror.org/019w4f821", "title"=>"EU - Horizon 2020"},
        {"count"=>1, "id"=>"https://ror.org/01zkghx44", "title"=>"Teasley Endowment to Georgia Tech"},
        {"count"=>1, "id"=>"https://ror.org/02t274463", "title"=>"UCSB"}
      ]

      expect(funders).to eq (expected_result)

    end
  end


# describe 'Clients', type: :controller do
#   let(:provider) { create(:provider) }
#   let(:model) { ClientsController.new }
#   let!(:clients)  { create_list(:client, 5, provider: provider) }
#   let(:params)  { {year: 2008} }
#   let(:params2)  { {year: clients.first.created.year} }

#   # describe "facet by year" do
#   #   before do
#   #     Provider.create(provider)
#   #     clients.each { |item| Client.create(item) }
#   #     sleep 2
#   #   end

#   #   it "should return nothing" do
#   #     puts Client.all
#   #     facet = model.facet_by_year params, Client.all
#   #     puts facet.class.name
#   #     puts facet.inspect
#   #     puts "chchc"
#   #     expect(facet.first[:count]).to eq(0)
#   #   end

#   #   it "should return all records" do
#   #     facet = model.facet_by_year params2, Client.all
#   #     puts facet
#   #     expect(facet.first[:count]).to eq(5)
#   #   end
#   # end
# end
