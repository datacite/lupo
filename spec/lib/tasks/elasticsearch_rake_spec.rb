# frozen_string_literal: true

require "rails_helper"

describe "elasticsearch:refresh_active_index_caches" do
  include_context "rake"
  include ThrowawayAliasedIndex

  let(:base) { throwaway_base }

  before do
    ENV.delete("MODELS")
  end

  after do
    ENV.delete("MODELS")
    delete_throwaway("#{base}_v1", "#{base}_v2")
    Rails.cache.delete(IndexAliasCoordination.cache_key(base))
    Rails.cache.delete(OtherDoi.active_index_cache_key)
  end

  it "replaces a stale key with the live alias target" do
    _v1, v2 = create_throwaway_pair(base, active: :v2)
    allow(DataciteDoi).to receive(:index_name).and_return(base)
    key = DataciteDoi.active_index_cache_key
    Rails.cache.write(key, "stale")
    ENV["MODELS"] = "DataciteDoi"

    output = capture_stdout { subject.invoke }

    expect(output).to include("#{base} \"stale\" -> #{v2.inspect}")
    expect(Rails.cache.read(key)).to eq(v2)
  end

  it "limits the refresh to MODELS" do
    create_throwaway_pair(base, active: :v1)
    allow(DataciteDoi).to receive(:index_name).and_return(base)
    datacite_key = DataciteDoi.active_index_cache_key
    other_key = OtherDoi.active_index_cache_key
    Rails.cache.write(datacite_key, "stale-datacite")
    Rails.cache.write(other_key, "stale-other")
    ENV["MODELS"] = "DataciteDoi"

    capture_stdout { subject.invoke }

    expect(Rails.cache.read(datacite_key)).to eq("#{base}_v1")
    expect(Rails.cache.read(other_key)).to eq("stale-other")
  end
end
