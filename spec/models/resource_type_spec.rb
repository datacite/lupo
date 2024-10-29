# frozen_string_literal: true

require "rails_helper"

RSpec.describe ResourceType, type: :model do
  describe "from new object" do
    let(:rt) { ResourceType.new({ "id" => "BookChapter", "title" => "BookChapter" }) }

    describe "attributes" do
      it "formats the id attribute correctly" do
        expect(rt.id).to eq("book-chapter")
      end

      it "has a correct title attribute" do
        expect(rt.title).to eq("BookChapter")
      end
    end
  end

  describe "class methods" do
    describe "#get_data" do
      it "has expected entries" do
        expect(ResourceType.get_data()).to include({ "id" => "audiovisual", "title" => "Audiovisual" },
          { "id" => "book", "title" => "Book" },
          { "id" => "book-chapter", "title" => "BookChapter" },
          { "id" => "collection", "title" => "Collection" },
          { "id" => "computational-notebook", "title" => "ComputationalNotebook" },
          { "id" => "conference-paper", "title" => "ConferencePaper" },
          { "id" => "conference-proceeding", "title" => "ConferenceProceeding" },
          { "id" => "data-paper", "title" => "DataPaper" },
          { "id" => "dataset", "title" => "Dataset" },
          { "id" => "dissertation", "title" => "Dissertation" },
          { "id" => "event", "title" => "Event" },
          { "id" => "image", "title" => "Image" },
          { "id" => "interactive-resource", "title" => "InteractiveResource" },
          { "id" => "journal", "title" => "Journal" },
          { "id" => "journal-article", "title" => "JournalArticle" },
          { "id" => "model", "title" => "Model" },
          { "id" => "output-management-plan", "title" => "OutputManagementPlan" },
          { "id" => "peer-review", "title" => "PeerReview" },
          { "id" => "physical-object", "title" => "PhysicalObject" },
          { "id" => "preprint", "title" => "Preprint" },
          { "id" => "report", "title" => "Report" },
          { "id" => "service", "title" => "Service" },
          { "id" => "software", "title" => "Software" },
          { "id" => "sound", "title" => "Sound" },
          { "id" => "standard", "title" => "Standard" },
          { "id" => "text", "title" => "Text" },
          { "id" => "workflow", "title" => "Workflow" },
          { "id" => "award", "title" => "Award" },
          { "id" => "project", "title" => "Project" },
          { "id" => "other", "title" => "Other" })
      end
    end

    describe "#parse_data" do
      # let(:rt) { ResourceType.parse_data(ResourceType.get_data(), options={ :id => "dissertation" }) }
      it "finds an item by id" do
        rt = ResourceType.parse_data(ResourceType.get_data(), { id: "dissertation" })
        expect(rt[:data]).to be_instance_of ResourceType
        expect(rt[:data].id).to eq("dissertation")
        expect(rt[:data].title).to eq("Dissertation")
      end

      it "returns nil for a non-existent resource type" do
        rt = ResourceType.parse_data(ResourceType.get_data(), { id: "fake-resource" })
        expect(rt).to be_nil
      end

      it "finds a single item by id query" do
        rt = ResourceType.parse_data(ResourceType.get_data(), { query: "softw" })
        expect(rt[:data][0]).to be_instance_of ResourceType
        expect(rt[:data][0].id).to eq("software")
        expect(rt[:data][0].title).to eq("Software")
        expect(rt[:meta]).to eq({ :total => 1, "total-pages" => 1, :page => 1 })
      end

      it "finds a single item by description query" do
        rt = ResourceType.parse_data(ResourceType.get_data(), { query: "managementplan" })
        expect(rt[:data][0]).to be_instance_of ResourceType
        expect(rt[:data][0].id).to eq("output-management-plan")
        expect(rt[:data][0].title).to eq("OutputManagementPlan")
        expect(rt[:meta]).to eq({ :total => 1, "total-pages" => 1, :page => 1 })
      end

      it "finds all items matching a query" do
        rt = ResourceType.parse_data(ResourceType.get_data(), { query: "conference" })
        expect(rt[:data][0]).to be_instance_of ResourceType
        expect(rt[:data][0].id).to eq("conference-paper")
        expect(rt[:data][0].title).to eq("ConferencePaper")
        expect(rt[:data][1]).to be_instance_of ResourceType
        expect(rt[:data][1].id).to eq("conference-proceeding")
        expect(rt[:data][1].title).to eq("ConferenceProceeding")
        expect(rt[:meta]).to eq({ :total => 2, "total-pages" => 1, :page => 1 })
      end

      it "returns empty results for a non-matching query" do
        rt = ResourceType.parse_data(ResourceType.get_data(), { query: "fake-resource" })
        expect(rt[:meta]).to eq({ :total => 0, "total-pages" => 0, :page => 1 })
      end

      it "returns multiple pages when necessary" do
        rt = ResourceType.parse_data(ResourceType.get_data(), { query: "a", page: { size: 5 } })
        expect(rt[:meta]).to include("total-pages" => (a_value > 1), :page => 1)
      end

      it "pages past the first page of results" do
        rt = ResourceType.parse_data(ResourceType.get_data(), { query: "a", page: { size: 5, number: 2 } })
        expect(rt[:meta]).to include("total-pages" => (a_value > 1), :page => 2)
      end
    end
  end
end
