require 'rails_helper'

describe "doi:index", elasticsearch: true do
  include ActiveJob::TestHelper
  include_context "rake"

  ENV['FROM_DATE'] = "2018-01-04"
  ENV['UNTIL_DATE'] = "2018-08-05"

  let!(:doi)  { create_list(:doi, 10) }
  let(:output) { "Queued indexing for DOIs created from 2018-01-04 until 2018-08-05.\n" }

  it "prerequisites should include environment" do
    expect(subject.prerequisites).to include("environment")
  end

  it "should run the rake task" do
    expect(capture_stdout { subject.invoke }).to eq(output)
  end

  it "should enqueue an DoiIndexByDayJob" do
    expect {
      capture_stdout { subject.invoke }
    }.to change(enqueued_jobs, :size).by(214)
    expect(enqueued_jobs.last[:job]).to be(DoiIndexByDayJob)
  end
end

describe "doi:index_by_day", elasticsearch: true do
  include ActiveJob::TestHelper
  include_context "rake"

  let!(:doi)  { create_list(:doi, 10) }
  let(:output) { "DOIs created on 2018-01-04 indexed.\n" }

  it "prerequisites should include environment" do
    expect(subject.prerequisites).to include("environment")
  end

  it "should run the rake task" do
    expect(capture_stdout { subject.invoke }).to eq(output)
  end
end