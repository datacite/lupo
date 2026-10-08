# frozen_string_literal: true

require "rails_helper"

describe "Other DOI number_of_shards", skip_prefix_pool: true do
  it "defaults to 5 on OtherDoi settings" do
    expect(ENV.fetch("NUMBER_OF_SHARDS_OTHER_DOI")).to eq("5")
    expect(OtherDoi.settings.to_hash.dig(:index, :number_of_shards)).to eq(5)
  end

  it "does not apply the OtherDoi shard setting to shared Doi settings" do
    expect(Doi.settings.to_hash.dig(:index, :number_of_shards)).to be_nil
    expect(OtherDoi.settings).not_to equal(Doi.settings)
    expect(OtherDoi.settings).not_to equal(DataciteDoi.settings)
  end

  it "uses OtherDoi.settings when building the OtherDoi template" do
    indices = Elasticsearch::Model.client.indices
    allow(indices).to receive(:exists_template?).and_return(false)
    expect(indices).to receive(:put_template) do |args|
      expect(args[:name]).to eq(OtherDoi.index_name)
      expect(args[:body][:index_patterns]).to eq(["#{OtherDoi.index_name}*"])
      expect(args[:body][:settings]).to eq(OtherDoi.settings.to_hash)
      expect(args[:body][:settings][:index][:number_of_shards]).to eq(5)
      expect(args[:body][:mappings]).to eq(Doi.mappings.to_hash)
      { "acknowledged" => true }
    end

    OtherDoi.create_template
  end

  it "keeps DataciteDoi templates on DataciteDoi settings" do
    indices = Elasticsearch::Model.client.indices
    allow(indices).to receive(:exists_template?).and_return(false)
    expect(indices).to receive(:put_template) do |args|
      expect(args[:name]).to eq(DataciteDoi.index_name)
      expect(args[:body][:index_patterns]).to eq(
        [DataciteDoi.index_name, "#{DataciteDoi.index_name}_v1", "#{DataciteDoi.index_name}_v2"],
      )
      expect(args[:body][:settings]).to eq(DataciteDoi.settings.to_hash)
      expect(args[:body][:settings][:index][:number_of_shards]).to eq(
        ENV.fetch("NUMBER_OF_SHARDS_DATACITE_DOI").to_i,
      )
      { "acknowledged" => true }
    end

    DataciteDoi.create_template
  end
end
