# frozen_string_literal: true

require "rails_helper"

describe EnrichedDoi, type: :model do
  it_behaves_like "an STI class"

  describe "database write protection" do
    let(:provider) { create(:provider) }
    let(:client) { create(:client, provider: provider) }
    let(:source_doi) { create(:doi, client: client, type: "DataciteDoi") }
    let(:enriched_doi) { EnrichedDoi.instantiate(source_doi.attributes) }

    it "is readonly" do
      expect(enriched_doi).to be_readonly
    end

    it "raises on save for a new record" do
      expect { EnrichedDoi.new.save }.to raise_error(ActiveRecord::ReadOnlyRecord)
    end

    it "raises on save for a persisted record" do
      expect { enriched_doi.save }.to raise_error(ActiveRecord::ReadOnlyRecord)
    end

    it "raises on update" do
      expect { enriched_doi.update(url: "https://example.com") }.to raise_error(ActiveRecord::ReadOnlyRecord)
    end

    it "raises on destroy" do
      expect { enriched_doi.destroy }.to raise_error(ActiveRecord::ReadOnlyRecord)
    end

    it "raises on delete" do
      expect { enriched_doi.delete }.to raise_error(ActiveRecord::ReadOnlyRecord)
    end
  end
end
