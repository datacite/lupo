# frozen_string_literal: true

require "rails_helper"

describe "Event number_of_shards" do
  it "defaults to 1 on Event settings" do
    expect(ENV.fetch("NUMBER_OF_SHARDS_EVENT")).to eq("1")
    expect(Event.settings.to_hash.dig(:index, :number_of_shards)).to eq(1)
  end

  it "does not apply the Event shard setting to shared Doi settings" do
    expect(Doi.settings.to_hash.dig(:index, :number_of_shards)).to be_nil
    expect(Event.settings).not_to equal(Activity.settings)
    expect(Event.settings).not_to equal(Doi.settings)
    expect(Event.mappings.to_hash[:properties]).to be_present
  end

  it "uses Event.settings when building the Event template" do
    indices = Elasticsearch::Model.client.indices
    allow(indices).to receive(:exists_template?).and_return(false)
    expect(indices).to receive(:put_template) do |args|
      expect(args[:name]).to eq(Event.index_name)
      expect(args[:body][:index_patterns]).to eq(["#{Event.index_name}*"])
      expect(args[:body][:settings]).to eq(Event.settings.to_hash)
      expect(args[:body][:settings][:index][:number_of_shards]).to eq(1)
      expect(args[:body][:mappings]).to eq(Event.mappings.to_hash)
      { "acknowledged" => true }
    end

    Event.create_template
  end
end
