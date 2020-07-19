require 'rails_helper'

describe "other_doi:create_index", elasticsearch: true, order: :defined do
  include ActiveJob::TestHelper
  include_context "rake"

  let!(:doi)  { create_list(:doi, 10) }
  let(:output) { "Created indexes dois-other-test_" }

  it "prerequisites should include environment" do
    expect(subject.prerequisites).to include("environment")
  end

  it "should run the rake task" do
    expect(capture_stdout { subject.invoke }).to start_with(output)
  end
end

describe "other_doi:delete_index", elasticsearch: true, order: :defined do
  include ActiveJob::TestHelper
  include_context "rake"

  let!(:doi)  { create_list(:doi, 10) }
  let(:output) { "Deleted indexes dois-other-test_v1 and dois-other-test_v2.\n" }

  it "prerequisites should include environment" do
    expect(subject.prerequisites).to include("environment")
  end

  it "should run the rake task" do
    Rake::Task["other_doi:create_index"].invoke
    expect(capture_stdout { subject.invoke }).to start_with(output)
  end
end

describe "other_doi:upgrade_index", elasticsearch: true, order: :defined do
  include ActiveJob::TestHelper
  include_context "rake"

  let!(:doi)  { create_list(:doi, 10) }
  let(:output) { "Upgraded inactive index dois-other-test" }

  it "prerequisites should include environment" do
    expect(subject.prerequisites).to include("environment")
  end

  it "should run the rake task" do
    Rake::Task["other_doi:create_index"].invoke
    expect(capture_stdout { subject.invoke }).to start_with(output)
  end
end

describe "other_doi:index_stats", elasticsearch: true, order: :defined do
  include ActiveJob::TestHelper
  include_context "rake"

  let!(:doi)  { create_list(:doi, 10) }
  let(:output) { "Active index dois-other-test_" }

  it "prerequisites should include environment" do
    expect(subject.prerequisites).to include("environment")
  end

  it "should run the rake task" do
    Rake::Task["other_doi:create_index"].invoke
    expect(capture_stdout { subject.invoke }).to start_with(output)
  end
end

describe "other_doi:switch_index", elasticsearch: true, order: :defined do
  include ActiveJob::TestHelper
  include_context "rake"

  let!(:doi)  { create_list(:doi, 10) }
  let(:output) { "Switched active index to dois-other-test" }

  it "prerequisites should include environment" do
    expect(subject.prerequisites).to include("environment")
  end

  it "should run the rake task" do
    expect(capture_stdout { subject.invoke }).to start_with(output)
  end
end

describe "other_doi:active_index", elasticsearch: true, order: :defined do
  include ActiveJob::TestHelper
  include_context "rake"

  let!(:doi)  { create_list(:doi, 10) }
  let(:output) { "dois-other-test_" }

  it "prerequisites should include environment" do
    expect(subject.prerequisites).to include("environment")
  end

  it "should run the rake task" do
    Rake::Task["other_doi:create_index"].invoke
    expect(capture_stdout { subject.invoke }).to start_with(output)
  end
end

describe "other_doi:start_aliases", elasticsearch: true, order: :defined do
  include ActiveJob::TestHelper
  include_context "rake"

  let!(:doi)  { create_list(:doi, 10) }
  let(:output) { "Index dois-other-test is already an alias.\n" }

  it "prerequisites should include environment" do
    expect(subject.prerequisites).to include("environment")
  end

  it "should run the rake task" do
    expect(capture_stdout { subject.invoke }).to start_with(output)
  end
end

describe "other_doi:monitor_reindex", elasticsearch: true, order: :defined do
  include ActiveJob::TestHelper
  include_context "rake"

  let!(:doi)  { create_list(:doi, 10) }
  let(:output) { "{}\n" }

  it "prerequisites should include environment" do
    expect(subject.prerequisites).to include("environment")
  end

  it "should run the rake task" do
    expect(capture_stdout { subject.invoke }).to start_with(output)
  end
end

describe "other_doi:finish_aliases", elasticsearch: true, order: :defined do
  include ActiveJob::TestHelper
  include_context "rake"

  let!(:doi)  { create_list(:doi, 10) }
  let(:output) { "Index dois-other-test is already an alias.\n" }

  it "prerequisites should include environment" do
    expect(subject.prerequisites).to include("environment")
  end

  it "should run the rake task" do
    Rake::Task["other_doi:create_index"].invoke
    expect(capture_stdout { subject.invoke }).to eq(output)
  end
end

describe "other_doi:import", elasticsearch: true, order: :defined do
  include ActiveJob::TestHelper
  include_context "rake"

  let!(:doi)  { create_list(:doi, 10, aasm_state: "findable") }
  let(:output) { "{:from_id=>0, :until_id=>0, :index=>\"dois-other-test_" }

  it "prerequisites should include environment" do
    expect(subject.prerequisites).to include("environment")
  end

  it "should run the rake task" do
    expect(capture_stdout { subject.invoke }).to start_with(output)
  end
end

describe "other_doi:import_one", elasticsearch: true, order: :defined do
  include ActiveJob::TestHelper
  include_context "rake"

  let(:doi)  { create(:doi) }
  let(:output) { "Imported DOI #{doi.doi}.\n" }

  it "prerequisites should include environment" do
    expect(subject.prerequisites).to include("environment")
  end

  it "should run the rake task" do
    ENV["DOI"] = doi.doi
    expect(capture_stdout { subject.invoke }).to start_with(output)
  end
end

describe "other_doi:index_one", elasticsearch: true, order: :defined do
  include ActiveJob::TestHelper
  include_context "rake"

  let!(:doi)  { create(:doi) }
  let(:output) { "Started indexing DOI #{doi.doi}.\n" }

  it "prerequisites should include environment" do
    expect(subject.prerequisites).to include("environment")
  end

  it "should run the rake task" do
    ENV["DOI"] = doi.doi
    expect(capture_stdout { subject.invoke }).to start_with(output)
  end
end
