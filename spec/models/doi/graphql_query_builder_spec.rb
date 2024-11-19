
# frozen_string_literal: true

require "rails_helper"

RSpec.describe Doi::GraphqlQuery::Builder do
  describe "page size" do
    let(:query) { "" }
    let(:options) { {} }
    let(:builder) { described_class.new(query, options) }

    it "is DEFAULT_PAGE_SIZE with no options" do
      expect(builder.size).to eq(described_class::DEFAULT_PAGE_SIZE)
    end

    context "when set in options" do
      let(:test_size) { 10 }
      let(:options) { { page: { size: test_size } } }
      it "will override DEFAULT_PAGE_SIZE" do
        expect(builder.size).to eq(test_size)
      end
    end
  end

  describe "cursor" do
    let(:query) { "" }
    let(:options) { {} }
    let(:builder) { described_class.new(query, options) }

    it "is DEFAULT_CURSOR with no options" do
      expect(builder.cursor).to eq(described_class::DEFAULT_CURSOR)
    end

    context "when set in options" do
      let(:test_cursor) { [1, "2"] }
      let(:options) { { page: { cursor: test_cursor } } }
      it "will override DEFAULT_CURSOR" do
        expect(builder.cursor).to eq(test_cursor)
      end
    end
  end

  describe "cleaned query" do
    it "is an empty string if not set" do
      expect(described_class.new("", {}).clean_query).to eq("")
      expect(described_class.new(nil, {}).clean_query).to eq("")
    end


    it "replaces several camelcase words with underscores" do
      described_class::QUERY_SUBSTITUTIONS.each do |key, value|
        expect(described_class.new(key, {}).clean_query).to eq(value)
      end
    end

    it "escapses foward slashes" do
      expect(described_class.new("foo/bar", {}).clean_query).to eq("foo\\/bar")
    end
  end

describe "#filters" do
  let(:query) { "" }
  let(:options) { {} }
  let(:builder) { described_class.new(query, options) }

  context "with basic filters" do
    context "when filtering by DOI ids" do
      let(:options) { { ids: "10.5438/0012,10.5438/0013" } }

      it "includes DOI terms filter" do
        expect(builder.filters).to include(
          { terms: { doi: ["10.5438/0012", "10.5438/0013"].map(&:upcase) } }
        )
      end
    end

    context "when filtering by resource type" do
      let(:options) { { resource_type: "dataset,text" } }

      it "includes resource type terms filter" do
        expect(builder.filters).to include(
          { terms: { "types.resourceType": ["dataset", "text"] } }
        )
      end
    end

    context "when filtering by language" do
      let(:options) { { language: "en,de" } }

      it "includes language terms filter" do
        expect(builder.filters).to include(
          { terms: { language: ["en", "de"].map(&:downcase) } }
        )
      end
    end
  end

    context "with date range filters" do
      let(:options) { { published: "2020,2022" } }

      it "handles publication year range" do
        expect(builder.filters).to include(
          { range: { publication_year: { gte: "2020||/y", lte: "2022||/y", format: "yyyy" } } }
        )
      end

      context "when filtering by created date" do
        let(:options) { { created: "2021,2023" } }

        it "handles created date range" do
          expect(builder.filters).to include(
            { range: { created: { gte: "2021||/y", lte: "2023||/y", format: "yyyy" } } }
          )
        end
      end
    end

    context "with count-based filters" do
      let(:options) { { has_views: "10" } }

      it "handles view count threshold" do
        expect(builder.filters).to include(
          { range: { view_count: { gte: 10 } } }
        )
      end

      context "when filtering by citations" do
        let(:options) { { has_citations: "5" } }

        it "handles citation count threshold" do
          expect(builder.filters).to include(
            { range: { citation_count: { gte: 5 } } }
          )
        end
      end
    end

    context "with subject-based filters" do
      let(:options) { { pid_entity: "dataset,software" } }

      it "handles pid entity filters" do
        expect(builder.filters).to include(
          { term: { "subjects.subjectScheme": "PidEntity" } },
          { terms: { "subjects.subject": ["Dataset", "Software"] } }
        )
      end

      context "when filtering by field of science" do
        let(:options) { { field_of_science: "computer_science,mathematics" } }

        it "handles field of science filters" do
          expect(builder.filters).to include(
            { term: { "subjects.subjectScheme": "Fields of Science and Technology (FOS)" } },
            { terms: { "subjects.subject": ["FOS: Computer science", "FOS: Mathematics"] } }
          )
        end
      end
    end

    context "with landing page filters" do
      let(:options) { { link_check_status: "200" } }

      it "handles landing page status" do
        expect(builder.filters).to include(
          { term: { "landing_page.status": "200" } }
        )
      end

      context "with schema.org check" do
        let(:options) { { link_check_has_schema_org: true } }

        it "handles schema.org presence check" do
          expect(builder.filters).to include(
            { term: { "landing_page.hasSchemaOrg": true } }
          )
        end
      end
    end

    context "with identifier filters" do
      context "with ids" do
        it "can filter for ids" do
          expect(described_class.new("foo", { ids: ["bar"] }).filters).to eq([{ terms: { doi: ["BAR"] } }])
        end

        it "can filter for ids as single string" do
          expect(described_class.new("foo", { ids: "bar" }).filters).to eq([{ terms: { doi: ["BAR"] } }])
        end
      end

      context "with certificate" do
        let(:options) { { certificate: "CoreTrustSeal,CLARIN" } }

        it "handles client certificate" do
          expect(builder.filters).to include(
            { terms: { "client.certificate" => ["CoreTrustSeal", "CLARIN"] } }
          )
        end
      end

      context "with ORCID" do
        let(:options) { { user_id: "https://orcid.org/0000-0003-1419-2405" } }

        it "handles user ORCID" do
          expect(builder.filters).to include(
            { terms: { "creators.nameIdentifiers.nameIdentifier" => ["https://orcid.org/0000-0003-1419-2405"] } }
          )
        end
      end
    end

    context "with multiple filters" do
      it "combines different filter types" do
        options = {
          resource_type: "dataset",
          published: "2020,2022",
          has_citations: "5",
          language: "en"
        }

        builder = described_class.new(query, options)
        filters = builder.filters

        expect(filters).to include(
          { terms: { "types.resourceType": ["dataset"] } },
          { range: { publication_year: { gte: "2020||/y", lte: "2022||/y", format: "yyyy" } } },
          { range: { citation_count: { gte: 5 } } },
          { terms: { language: ["en"] } }
        )
        expect(filters.length).to eq(4)
      end
    end

    context "with empty or invalid filters" do
      it "handles empty options" do
        builder = described_class.new(query, {})
        expect(builder.filters).to be_empty
      end

      it "handles nil values" do
        options = { resource_type: nil, language: nil }
        builder = described_class.new(query, options)
        expect(builder.filters).to be_empty
      end
    end
  end

  describe "filters"  do

  end
end
