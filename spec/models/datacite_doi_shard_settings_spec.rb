# frozen_string_literal: true

require "rails_helper"

describe "Datacite DOI number_of_shards" do
  it "defaults to 1 on DataciteDoi settings" do
    expect(ENV.fetch("NUMBER_OF_SHARDS_DATACITE_DOI")).to eq("1")
    expect(DataciteDoi.settings.to_hash.dig(:index, :number_of_shards)).to eq(1)
  end

  it "does not apply the shard setting to OtherDoi or shared Doi settings" do
    expect(Doi.settings.to_hash.dig(:index, :number_of_shards)).to be_nil
    expect(OtherDoi.settings.to_hash.dig(:index, :number_of_shards)).to be_nil
  end

  it "uses DataciteDoi.settings when building the Datacite template" do
    indices = Elasticsearch::Model.client.indices
    allow(indices).to receive(:exists_template?).and_return(false)
    expect(indices).to receive(:put_template) do |args|
      expect(args[:name]).to eq(DataciteDoi.index_name)
      expect(args[:body][:index_patterns]).to eq(
        [DataciteDoi.index_name, "#{DataciteDoi.index_name}_v1", "#{DataciteDoi.index_name}_v2"],
      )
      expect(args[:body][:settings]).to eq(DataciteDoi.settings.to_hash)
      expect(args[:body][:settings][:index][:number_of_shards]).to eq(1)
      { "acknowledged" => true }
    end

    DataciteDoi.create_template
  end

  it "keeps OtherDoi templates free of the Datacite shard setting" do
    indices = Elasticsearch::Model.client.indices
    allow(indices).to receive(:exists_template?).and_return(false)
    expect(indices).to receive(:put_template) do |args|
      expect(args[:name]).to eq(OtherDoi.index_name)
      expect(args[:body][:index_patterns]).to eq(["#{OtherDoi.index_name}*"])
      expect(args[:body][:settings]).to eq(Doi.settings.to_hash)
      expect(args[:body][:settings].dig(:index, :number_of_shards)).to be_nil
      { "acknowledged" => true }
    end

    OtherDoi.create_template
  end
end
