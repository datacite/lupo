# frozen_string_literal: true

require "rails_helper"

describe DataciteDoi, type: :model, vcr: true do
  it_behaves_like "an STI class"

  describe "import_by_ids", elasticsearch: true do
    let(:provider) { create(:provider) }
    let(:client) { create(:client, provider: provider) }
    let!(:dois) do
      create_list(
        :doi,
        3,
        client: client, aasm_state: "findable", type: "DataciteDoi",
      )
    end
    let(:doi) { dois.first }

    it "import by ids" do
      response = DataciteDoi.import_by_ids
      expect(response).to be > 0
    end
  end
end
