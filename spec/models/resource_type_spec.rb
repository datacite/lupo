require 'rails_helper'

describe ResourceType, type: :model, vcr: true do
  it "all" do
    resource_types = ResourceType.all[:data]
    expect(resource_types.length).to eq(14)
    resource_type = resource_types.first
    expect(resource_type.title).to eq("Audiovisual")
  end

  it "one" do
    resource_type = ResourceType.where(id: "text")[:data]
    expect(resource_type.title).to eq("Text")
  end
end
