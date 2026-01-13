# frozen_string_literal: true

require "rails_helper"

describe EventsPreloader do
  let(:client) { create(:client) }
  let(:doi1) { create(:doi, client: client, doi: "10.1234/TEST1", aasm_state: "findable") }
  let(:doi2) { create(:doi, client: client, doi: "10.1234/TEST2", aasm_state: "findable") }
  let(:doi3) { create(:doi, client: client, doi: "10.1234/TEST3", aasm_state: "findable") }

  describe "#initialize" do
    it "initializes preloaded_events for each DOI" do
      dois = [doi1, doi2]
      EventsPreloader.new(dois)

      expect(doi1.preloaded_events).to eq([])
      expect(doi2.preloaded_events).to eq([])
    end

    it "handles empty array" do
      preloader = EventsPreloader.new([])
      expect { preloader.preload! }.not_to raise_error
    end
  end

  describe "#preload!" do
    context "with source and target events" do
      let!(:reference_event) do
        create(:event_for_crossref, {
          subj_id: "https://doi.org/#{doi1.doi}",
          obj_id: "https://doi.org/#{doi2.doi}",
          relation_type_id: "references",
        })
      end
      let!(:citation_event) do
        create(:event_for_datacite_crossref, {
          subj_id: "https://doi.org/#{doi3.doi}",
          obj_id: "https://doi.org/#{doi1.doi}",
          relation_type_id: "is-referenced-by",
        })
      end
      let!(:part_event) do
        create(:event_for_datacite_parts, {
          subj_id: "https://doi.org/#{doi1.doi}",
          obj_id: "https://doi.org/#{doi3.doi}",
          relation_type_id: "has-part",
        })
      end

      it "loads all events for the DOIs" do
        dois = [doi1, doi2, doi3]
        EventsPreloader.new(dois).preload!

        # doi1 should have reference_event (as source) and citation_event (as target)
        expect(doi1.preloaded_events.length).to eq(2)
        expect(doi1.preloaded_events).to include(reference_event, citation_event)

        # doi2 should have reference_event (as target)
        expect(doi2.preloaded_events.length).to eq(1)
        expect(doi2.preloaded_events).to include(reference_event)

        # doi3 should have citation_event (as source) and part_event (as target)
        expect(doi3.preloaded_events.length).to eq(2)
        expect(doi3.preloaded_events).to include(citation_event, part_event)
      end

      it "makes only one database query" do
        dois = [doi1, doi2, doi3]
        preloader = EventsPreloader.new(dois)

        expect {
          preloader.preload!
        }.not_to exceed_query_limit(1)
      end
    end

    context "with no events" do
      it "sets empty arrays for all DOIs" do
        dois = [doi1, doi2]
        EventsPreloader.new(dois).preload!

        expect(doi1.preloaded_events).to eq([])
        expect(doi2.preloaded_events).to eq([])
      end
    end

    context "with large batch" do
      it "chunks large DOI lists" do
        # Create more than CHUNK_SIZE DOIs
        large_batch = create_list(:doi, EventsPreloader::CHUNK_SIZE + 100, client: client, aasm_state: "findable")

        # Create events for some of them
        create(:event_for_crossref, {
          subj_id: "https://doi.org/#{large_batch.first.doi}",
          obj_id: "https://doi.org/#{large_batch.last.doi}",
          relation_type_id: "references",
        })

        expect {
          EventsPreloader.new(large_batch).preload!
        }.not_to raise_error

        expect(large_batch.first.preloaded_events).not_to be_nil
      end
    end

    context "with case-insensitive DOI matching" do
      let!(:event) do
        create(:event_for_crossref, {
          subj_id: "https://doi.org/#{doi1.doi.downcase}",
          obj_id: "https://doi.org/#{doi2.doi.downcase}",
          relation_type_id: "references",
        })
      end

      it "matches DOIs regardless of case" do
        dois = [doi1, doi2]
        EventsPreloader.new(dois).preload!

        expect(doi1.preloaded_events).to include(event)
        expect(doi2.preloaded_events).to include(event)
      end
    end
  end

  describe "integration with Doi model" do
    let!(:reference_event) do
      create(:event_for_crossref, {
        subj_id: "https://doi.org/#{doi1.doi}",
        obj_id: "https://doi.org/#{doi2.doi}",
        relation_type_id: "references",
      })
    end
    let!(:citation_event) do
      create(:event_for_datacite_crossref, {
        subj_id: "https://doi.org/#{doi3.doi}",
        obj_id: "https://doi.org/#{doi1.doi}",
        relation_type_id: "is-referenced-by",
      })
    end

    it "allows Doi methods to use preloaded events" do
      dois = [doi1, doi2, doi3]
      EventsPreloader.new(dois).preload!

      # These should use preloaded_events instead of querying the database
      expect(doi1.reference_events.to_a).to include(reference_event)
      expect(doi1.citation_events.to_a).to include(citation_event)
      expect(doi1.reference_count).to eq(1)
      expect(doi1.citation_count).to eq(1)
    end

    it "maintains backward compatibility when preloaded_events is nil" do
      # When preloaded_events is nil, should fall back to database queries
      expect(doi1.preloaded_events).to be_nil
      expect(doi1.reference_events.to_a).to include(reference_event)
      expect(doi1.citation_events.to_a).to include(citation_event)
    end
  end
end
