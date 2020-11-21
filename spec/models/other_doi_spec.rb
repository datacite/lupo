require "rails_helper"

describe OtherDoi, type: :model, vcr: true do
  it_behaves_like "an STI class"

  describe "import_by_ids", elasticsearch: true do
    let!(:dois) { create_list(:doi, 3, aasm_state: "findable", type: "OtherDoi") }
    let(:doi) { dois.first }

    it "import by ids" do
      response = OtherDoi.import_by_ids
      expect(response).to be > 0
    end

    it "import by id" do
      response = OtherDoi.import_by_id(id: doi.id)
      expect(response).to eq(3)
    end
  end
end
