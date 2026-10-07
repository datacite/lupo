# frozen_string_literal: true

require "rails_helper"

describe "Activity number_of_shards" do
  it "defaults to 1 on Activity settings" do
    expect(ENV.fetch("NUMBER_OF_SHARDS_ACTIVITY")).to eq("1")
    expect(Activity.settings.to_hash.dig(:index, :number_of_shards)).to eq(1)
  end

  it "does not apply the Activity shard setting to shared Doi settings" do
    expect(Doi.settings.to_hash.dig(:index, :number_of_shards)).to be_nil
    expect(Activity.settings).not_to equal(Event.settings)
    expect(Activity.settings).not_to equal(Doi.settings)
    expect(Activity.mappings.to_hash[:properties]).to be_present
  end

  it "uses Activity.settings when building the Activity template" do
    indices = Elasticsearch::Model.client.indices
    allow(indices).to receive(:exists_template?).and_return(false)
    expect(indices).to receive(:put_template) do |args|
      expect(args[:name]).to eq(Activity.index_name)
      expect(args[:body][:index_patterns]).to eq(["#{Activity.index_name}*"])
      expect(args[:body][:settings]).to eq(Activity.settings.to_hash)
      expect(args[:body][:settings][:index][:number_of_shards]).to eq(1)
      expect(args[:body][:mappings]).to eq(Activity.mappings.to_hash)
      { "acknowledged" => true }
    end

    Activity.create_template
  end
end
