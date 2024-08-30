
# frozen_string_literal: true

require "rails_helper"

describe Doi, type: :model, vcr: true, elasticsearch: true do
  describe "views" do
    let(:client) { create(:client) }
    let(:doi) { create(:doi, client: client, aasm_state: "findable") }
    let!(:views) { create_list(:event_for_datacite_investigations, 3, obj_id: "https://doi.org/#{doi.doi}", relation_type_id: "unique-dataset-investigations-regular", total: 25) }

    it "has views" do
      expect(doi.view_events.count).to eq(3)
      expect(doi.view_count).to eq(75)
      expect(doi.views_over_time.first).to eq("total" => 25, "yearMonth" => "2015-06")

      view = doi.view_events.first
      expect(view.target_doi).to eq(doi.doi)
      expect(view.total).to eq(25)
    end
  end


  describe "N+1 safety" do
    describe ".import_in_bulk" do
      let(:ids) { [1, 2, 3] }

      it "should make only one db call" do
        allow(DataciteDoi).to receive(:upload_to_elasticsearch)

        # Test the maximum number of queries made by the method
        expect {
          DataciteDoi.import_in_bulk(ids)
        }.not_to exceed_query_limit(1)
      end
    end

    describe ".as_indexed_json" do
      let(:client) { create(:client) }
      let(:doi) { create(:doi, client: client, aasm_state: "findable") }

      it "should make few db call" do
        allow(DataciteDoi).to receive(:upload_to_elasticsearch)
        dois = DataciteDoi.where(id: doi.id).includes(
          :client,
          :media,
          :view_events,
          :download_events,
          :citation_events,
          :reference_events,
          :part_events,
          :part_of_events,
          :version_events,
          :version_of_events,
          :metadata
        )

        # Test the maximum number of queries made by the method
        expect {
          dois.first.as_indexed_json
        }.not_to exceed_query_limit(13)
      end
    end
  end

  describe "downloads" do
    let(:client) { create(:client) }
    let(:doi) { create(:doi, client: client, aasm_state: "findable") }
    let!(:downloads) { create_list(:event_for_datacite_investigations, 3, obj_id: "https://doi.org/#{doi.doi}", relation_type_id: "unique-dataset-requests-regular", total: 10) }

    it "has downloads" do
      expect(doi.download_events.count).to eq(3)
      expect(doi.download_count).to eq(30)
      expect(doi.downloads_over_time.first).to eq("total" => 10, "yearMonth" => "2015-06")

      download = doi.download_events.first
      expect(download.target_doi).to eq(doi.doi)
      expect(download.total).to eq(10)
    end
  end

  describe "references" do
    let(:client) { create(:client) }
    let(:doi) { create(:doi, client: client, aasm_state: "findable") }
    let(:target_doi) { create(:doi, client: client, aasm_state: "findable") }
    let!(:reference_event) do
      create(:event_for_crossref, {
        subj_id: "https://doi.org/#{doi.doi}",
        obj_id: "https://doi.org/#{target_doi.doi}",
        relation_type_id: "references",
        occurred_at: "2015-06-13T16:14:19Z",
      })
    end
    let!(:reference_event2) do
      create(:event_for_crossref, {
        subj_id: "https://doi.org/#{target_doi.doi}",
        obj_id: "https://doi.org/#{doi.doi}",
        occurred_at: "2016-06-13T16:14:19Z",
        relation_type_id: "is-referenced-by",
      })
    end

    it "has references" do
      # Some older events have downcased source_doi and target_doi
      reference_event2.target_doi = target_doi.doi.downcase
      reference_event2.source_doi = doi.doi.downcase
      reference_event2.save

      expect(doi.references.count).to eq(2)
      expect(doi.reference_ids.count).to eq(1)
      expect(doi.reference_count).to eq(1)

      reference_id = doi.reference_ids.first
      expect(reference_id).to eq(target_doi.doi.downcase)
    end
  end

  describe "citations" do
    let(:client) { create(:client) }
    let(:doi) { create(:doi, client: client, aasm_state: "findable") }
    let(:source_doi) { create(:doi, client: client, aasm_state: "findable") }
    let(:source_doi2) { create(:doi, client: client, aasm_state: "findable") }
    let!(:citation_event) do
      create(:event_for_datacite_crossref, {
        subj_id: "https://doi.org/#{doi.doi}",
        obj_id: "https://doi.org/#{source_doi.doi}",
        relation_type_id: "is-referenced-by",
        occurred_at: "2015-06-13T16:14:19Z"
      })
    end
    let!(:citation_event2) do
      create(:event_for_datacite_crossref, {
        subj_id: "https://doi.org/#{doi.doi}",
        obj_id: "https://doi.org/#{source_doi2.doi}",
        relation_type_id: "is-referenced-by",
        occurred_at: "2016-06-13T16:14:19Z"
      })
    end
    let!(:citation_event3) do
      create(:event_for_datacite_crossref, {
        subj_id: "https://doi.org/#{doi.doi}",
        obj_id: "https://doi.org/#{source_doi2.doi}",
        relation_type_id: "is-cited-by",
        occurred_at: "2016-06-13T16:14:19Z"
      })
    end
    let!(:citation_event4) do
      create(:event_for_datacite_crossref, {
        subj_id: "https://doi.org/#{source_doi2.doi}",
        obj_id: "https://doi.org/#{doi.doi}",
        relation_type_id: "cites",
        source_id: "crossref",
        occurred_at: "2017-06-13T16:14:19Z"
      })
    end

    # removing duplicate dois in citation_ids, citation_count and citations_over_time (different relation_type_id)
    it "has citations" do
      # Some older events have downcased source_doi and target_doi
      citation_event4.source_doi = source_doi2.doi.downcase
      citation_event4.target_doi = doi.doi.downcase
      citation_event4.save

      expect(doi.citations.count).to eq(4)
      expect(doi.citation_ids.count).to eq(2)
      expect(doi.citation_count).to eq(2)
      expect(doi.citations_over_time).to eq([{ "total" => 1, "year" => "2015" }, { "total" => 1, "year" => "2016" }])

      citation_id = doi.citation_ids.first
      expect(citation_id).to eq(source_doi.doi.downcase)
    end
  end

  describe "parts" do
    let(:client) { create(:client) }
    let(:doi) { create(:doi, client: client, aasm_state: "findable") }
    let(:target_doi) { create(:doi, client: client, aasm_state: "findable") }
    let!(:part_events) { create(:event_for_datacite_parts, subj_id: "https://doi.org/#{doi.doi}", obj_id: "https://doi.org/#{target_doi.doi}", relation_type_id: "has-part") }

    it "has parts" do
      expect(doi.parts.count).to eq(1)
      expect(doi.part_ids.count).to eq(1)
      expect(doi.part_count).to eq(1)

      part_id = doi.part_ids.first
      expect(part_id).to eq(target_doi.doi.downcase)
    end
  end

  describe "part of" do
    let(:client) { create(:client) }
    let(:doi) { create(:doi, client: client, aasm_state: "findable") }
    let(:source_doi) { create(:doi, client: client, aasm_state: "findable") }
    let!(:part_of_events) { create(:event_for_datacite_part_of, subj_id: "https://doi.org/#{doi.doi}", obj_id: "https://doi.org/#{source_doi.doi}", relation_type_id: "is-part-of") }

    it "has part of" do
      expect(doi.part_of.count).to eq(1)
      expect(doi.part_of_ids.count).to eq(1)
      expect(doi.part_of_count).to eq(1)

      part_of_id = doi.part_of_ids.first
      expect(part_of_id).to eq(source_doi.doi.downcase)
    end
  end

  describe "versions" do
    let(:client) { create(:client) }
    let(:doi) { create(:doi, client: client, aasm_state: "findable") }
    let(:target_doi) { create(:doi, client: client, aasm_state: "findable") }
    let!(:version_event) { create(:event_for_datacite_versions, subj_id: "https://doi.org/#{doi.doi}", obj_id: "https://doi.org/#{target_doi.doi}") }

    it "has versions" do
      expect(doi.versions.count).to eq(1)
      expect(doi.version_ids.count).to eq(1)
      expect(doi.version_count).to eq(1)

      version_id = doi.version_ids.first
      expect(version_id).to eq(target_doi.doi.downcase)
    end
  end

  describe "version of" do
    let(:client) { create(:client) }
    let(:doi) { create(:doi, client: client, aasm_state: "findable") }
    let(:source_doi) { create(:doi, client: client, aasm_state: "findable") }
    let!(:version_of_events) { create(:event_for_datacite_version_of, subj_id: "https://doi.org/#{doi.doi}", obj_id: "https://doi.org/#{source_doi.doi}") }

    it "has version of" do
      expect(doi.version_of.count).to eq(1)
      expect(doi.version_of_ids.count).to eq(1)
      expect(doi.version_of_count).to eq(1)

      version_of_id = doi.version_of_ids.first
      expect(version_of_id).to eq(source_doi.doi.downcase)
    end
  end

  describe "other relation types" do
    let(:client) { create(:client) }
    let(:doi) { create(:doi, client: client, aasm_state: "findable") }

    let!(:ref_target_dois) { create_list(:doi, 5, client: client, aasm_state: "findable") }
    let!(:reference_events) do
      ref_target_dois.each do |ref_target_doi|
        create(:event_for_crossref, {
          subj_id: "https://doi.org/#{doi.doi}",
          obj_id: "https://doi.org/#{ref_target_doi.doi}",
          relation_type_id: "references"
        })
      end
    end
    let!(:citation_target_dois) { create_list(:doi, 7, client: client, aasm_state: "findable") }
    let!(:citation_events) do
      citation_target_dois.each do |citation_target_doi|
        create(:event_for_datacite_crossref, {
          subj_id: "https://doi.org/#{doi.doi}",
          obj_id: "https://doi.org/#{citation_target_doi.doi}",
          relation_type_id: "is-referenced-by"
        })
      end
    end

    let!(:version_target_dois) { create_list(:doi, 3, client: client, aasm_state: "findable") }
    let!(:version_events) do
      version_target_dois.each do |version_target_doi|
        create(:event_for_datacite_versions, {
          subj_id: "https://doi.org/#{doi.doi}",
          obj_id: "https://doi.org/#{version_target_doi.doi}"
        })
      end
    end

    let!(:part_target_dois) { create_list(:doi, 9, client: client, aasm_state: "findable") }
    let!(:part_events) do
      part_target_dois.each do |part_target_doi|
        create(:event_for_datacite_parts, {
          subj_id: "https://doi.org/#{doi.doi}",
          obj_id: "https://doi.org/#{part_target_doi.doi}",
          relation_type_id: "has-part"
        })
      end
    end

    it "references exist" do
      expect(doi.references.count).to eq(5)
      expect(doi.reference_count).to eq(5)
    end

    it "citations exist" do
      expect(doi.citations.count).to eq(7)
      expect(doi.citation_count).to eq(7)
    end

    it "versions exist" do
      expect(doi.versions.count).to eq(3)
      expect(doi.version_count).to eq(3)
    end

    it "parts exist" do
      expect(doi.parts.count).to eq(9)
      expect(doi.part_count).to eq(9)
    end

    it "other_relations should not include citations,parts,references" do
      Event.import
      sleep 2
      expect(doi.other_relation_ids.length).to eq(3)
      expect(doi.other_relation_count).to eq(3)
    end
  end
end
