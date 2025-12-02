

# frozen_string_literal: true

require "rails_helper"

RSpec.describe Doi::GraphqlQuery::Builder do
  let(:query) { "" }
  let(:options) { {} }

  describe "filters" do
    context "with basic filters" do
      it "handles DOI ids" do
        options = { ids: "10.5438/0012,10.5438/0013" }
        builder = described_class.new(query, options)
        expect(builder.filters).to include(
          { terms: { doi: ["10.5438/0012", "10.5438/0013"].map(&:upcase) } }
        )
      end

      it "handles resource_type_id" do
        options = { resource_type_id: "Journal_Article" }
        builder = described_class.new(query, options)
        expect(builder.filters).to include(
          { term: { resource_type_id: "journal-article" } }
        )
      end

      it "handles resource type" do
        options = { resource_type: "dataset,text" }
        builder = described_class.new(query, options)
        expect(builder.filters).to include(
          { terms: { "types.resourceType": ["dataset", "text"] } }
        )
      end


      it "handles agency" do
        options = { agency: "crossref" }
        builder = described_class.new(query, options)
        expect(builder.filters).to include(
          { terms: { agency: ["crossref"].map(&:downcase) } }
        )
      end

      it "handles prefix" do
        options = { prefix: "10.5438" }
        builder = described_class.new(query, options)
        expect(builder.filters).to include(
          { terms: { prefix: ["10.5438"].map(&:downcase) } }
        )
      end

      it "handles language" do
        options = { language: "en,de" }
        builder = described_class.new(query, options)
        expect(builder.filters).to include(
          { terms: { language: ["en", "de"].map(&:downcase) } }
        )
      end

      it "handles uid" do
        options = { uid: "10.5438/0012" }
        builder = described_class.new(query, options)
        expect(builder.filters).to include(
          { term: { uid: "10.5438/0012" } }
        )
      end

      it "handles state" do
        options = { state: "findable,registered" }
        builder = described_class.new(query, options)
        expect(builder.filters).to include(
          { terms: { aasm_state: ["findable", "registered"] } }
        )
      end

      it "handles consortium_id" do
        options = { consortium_id: "dc" }
        builder = described_class.new(query, options)
        expect(builder.filters).to include(
          { term: { consortium_id: { case_insensitive: true, value: "dc" } } }
        )
      end

      it "handles registered" do
        options = { registered: "2021,2023" }
        builder = described_class.new(query, options)
        expect(builder.filters).to include(
          { range: { registered: { gte: "2021||/y", lte: "2023||/y", format: "yyyy" } } }
        )
      end
    end

    context "filters based on client metadata" do
      it "handles re3data_id" do
        options = { re3data_id: "10.17616/r31njmjx" }
        builder = described_class.new(query, options)
        expect(builder.filters).to include(
          { term: { "client.re3data_id" => "10.17616/r31njmjx" } }
        )
      end

      it "handles opendoar_id" do
        options = { opendoar_id: "123456" }
        builder = described_class.new(query, options)
        expect(builder.filters).to include(
          { term: { "client.opendoar_id" => "123456" } }
        )
      end

      it "handles certificates" do
        options = { certificate: "CoreTrustSeal,WDS" }
        builder = described_class.new(query, options)
        expect(builder.filters).to include(
          { terms: { "client.certificate" => ["CoreTrustSeal", "WDS"] } }
        )
      end
    end

    context "with date range filters" do
      it "handles publication year range" do
        options = { published: "2020,2022" }
        builder = described_class.new(query, options)
        expect(builder.filters).to include(
          { range: { publication_year: { gte: "2020||/y", lte: "2022||/y", format: "yyyy" } } }
        )
      end

      it "handles created date range" do
        options = { created: "2021,2023" }
        builder = described_class.new(query, options)
        expect(builder.filters).to include(
          { range: { created: { gte: "2021||/y", lte: "2023||/y", format: "yyyy" } } }
        )
      end
    end

    context "with count-based filters" do
      it "handles reference count threshold" do
        options = { has_references: "5" }
        builder = described_class.new(query, options)
        expect(builder.filters).to include(
          { range: { reference_count: { gte: 5 } } }
        )
      end

      it "handles citation count threshold" do
        options = { has_citations: "5" }
        builder = described_class.new(query, options)
        expect(builder.filters).to include(
          { range: { citation_count: { gte: 5 } } }
        )
      end

      it "handles part count threshold" do
        options = { has_parts: "10" }
        builder = described_class.new(query, options)
        expect(builder.filters).to include(
          { range: { part_count: { gte: 10 } } }
        )
      end

      it "handles part of count threshold" do
        options = { has_part_of: "10" }
        builder = described_class.new(query, options)
        expect(builder.filters).to include(
          { range: { part_of_count: { gte: 10 } } }
        )
      end

      it "handles version count threshold" do
        options = { has_versions: "10" }
        builder = described_class.new(query, options)
        expect(builder.filters).to include(
          { range: { version_count: { gte: 10 } } }
        )
      end

      it "handles version of count threshold" do
        options = { has_version_of: "10" }
        builder = described_class.new(query, options)
        expect(builder.filters).to include(
          { range: { version_of_count: { gte: 10 } } }
        )
      end

      it "handles view count threshold" do
        options = { has_views: "10" }
        builder = described_class.new(query, options)
        expect(builder.filters).to include(
          { range: { view_count: { gte: 10 } } }
        )
      end

      it "handles download count threshold" do
        options = { has_downloads: "10" }
        builder = described_class.new(query, options)
        expect(builder.filters).to include(
          { range: { download_count: { gte: 10 } } }
        )
      end
    end

    context "with subject-based filters" do
      it "handles pid entity filters" do
        options = { pid_entity: "dataset,software" }
        builder = described_class.new(query, options)
        expect(builder.filters).to include(
          { term: { "subjects.subjectScheme": "PidEntity" } },
          { terms: { "subjects.subject.keyword": ["Dataset", "Software"] } }
        )
      end

      it "handles field of science filters" do
        options = { field_of_science: "computer_science,mathematics" }
        builder = described_class.new(query, options)
        expect(builder.filters).to include(
          { term: { "subjects.subjectScheme": "Fields of Science and Technology (FOS)" } },
          { terms: { "subjects.subject.keyword": ["FOS: Computer science", "FOS: Mathematics"] } }
        )
      end
    end

    context "with landing page filters" do
      it "handles landing page status" do
        options = { link_check_status: "200" }
        builder = described_class.new(query, options)
        expect(builder.filters).to include(
          { term: { "landing_page.status": "200" } }
        )
      end

      it "handles schema.org presence check" do
        options = { link_check_has_schema_org: true }
        builder = described_class.new(query, options)
        expect(builder.filters).to include(
          { term: { "landing_page.hasSchemaOrg": true } }
        )
      end
    end

    context "with identifier filters" do
      context "with ids" do
        it "can filter for ids" do
          expect(described_class.new("foo", { ids: ["bar"] }).filters).to eq(
            [{ terms: { doi: ["BAR"] } }]
          )
        end

        it "can filter for ids as single string" do
          expect(described_class.new("foo", { ids: "bar" }).filters).to eq([{ terms: { doi: ["BAR"] } }])
        end
      end

      it "handles client certificate" do
        builder = described_class.new(query, { certificate: "CoreTrustSeal,CLARIN" })
        expect(builder.filters).to include(
          { terms: { "client.certificate" => ["CoreTrustSeal", "CLARIN"] } }
        )
      end

      it "handles user ORCID" do
        expect(described_class.new(query, { user_id: "https://orcid.org/0000-0003-1419-2405" }).filters).to include(
          { terms: { "creators.nameIdentifiers.nameIdentifier" => ["https://orcid.org/0000-0003-1419-2405"] } }
        )
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
end
