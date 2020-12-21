# frozen_string_literal: true

require "rails_helper"

describe DataciteDoi, type: :model, vcr: true do
  it_behaves_like "an STI class"

  describe "import_by_ids", elasticsearch: true do
    let(:provider) { create(:provider) }
    let(:client) { create(:client, provider: provider) }
    let(:target) do
      create(
        :client,
        provider: provider,
        symbol: provider.symbol + ".TARGET",
        name: "Target Client",
      )
    end
    let!(:dois) do
      create_list(
        :doi,
        3,
        client: client, aasm_state: "findable", type: "DataciteDoi",
      )
    end
    let(:doi) { dois.first }

    it "import by ids" do
      response = Doi.import_by_ids(model: "DataciteDoi")
      expect(response).to be > 0
    end

    it "import by id" do
      response = Doi.import_by_id(model: "DataciteDoi", id: doi.id)
      expect(response).to eq(3)
    end
  end
end
