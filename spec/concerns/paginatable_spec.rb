require "rails_helper"

describe "Dois", type: :controller do
  subject { DataciteDoisController.new }
  
  it "no params" do
    params = ActionController::Parameters.new
    expect(subject.page_from_params(params)).to eq(:number=>1, :size=>25)
  end

  it "page as string" do
    params = ActionController::Parameters.new({ page: "3" })
    expect(subject.page_from_params(params)).to eq(:number=>1, :size=>25)
  end

  it "page number" do
    params = ActionController::Parameters.new({ page: { number: "3" }})
    expect(subject.page_from_params(params)).to eq(:number=>3, :size=>25)
  end

  it "page number too high" do
    params = ActionController::Parameters.new({ page: { number: "401" }})
    expect(subject.page_from_params(params)).to eq(:number=>400, :size=>25)
  end

  it "page size" do
    params = ActionController::Parameters.new({ page: { size: "250" }})
    expect(subject.page_from_params(params)).to eq(:number=>1, :size=>250)
  end

  it "page size too high" do
    params = ActionController::Parameters.new({ page: { size: "1001" }})
    expect(subject.page_from_params(params)).to eq(:number=>1, :size=>1000)
  end

  it "page cursor" do
    params = ActionController::Parameters.new({ page: { cursor: "MTMwMjUyMTAxNjAwMCwxMC40MTIyLzEuMTAwMDAwMDAyMg" }})
    expect(subject.page_from_params(params)).to eq(cursor: ["1302521016000", "10.4122/1.1000000022"], number: 1, size: 25)
  end

  it "page invalid cursor" do
    params = ActionController::Parameters.new({ page: { cursor: "A" }})
    expect(subject.page_from_params(params)).to eq(cursor: [], number: 1, size: 25)
  end

  it "page empty cursor" do
    params = ActionController::Parameters.new({ page: { cursor: nil }})
    expect(subject.page_from_params(params)).to eq(cursor: [], number: 1, size: 25)
  end
end
