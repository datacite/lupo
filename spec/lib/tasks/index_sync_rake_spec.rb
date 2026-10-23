# frozen_string_literal: true

require "rails_helper"

describe "index_sync:status" do
  include_context "rake"

  def cache_keys
    SharedContainerSettings::INDEX_SYNC_MODELS.map { |name| name.constantize.active_index_cache_key }
  end

  before do
    cache_keys.each { |key| Rails.cache.delete(key) }
  end

  after do
    cache_keys.each { |key| Rails.cache.delete(key) }
  end

  it "reports NOT CACHED and does not populate the cache" do
    output = capture_stdout { subject.invoke }

    expect(output).to include("NOT CACHED")
    expect(output).to include("cached=nil")
    cache_keys.each do |key|
      expect(Rails.cache.read(key)).to be_nil
    end
  end

  it "reports DRIFT when a cached value disagrees with the live alias" do
    key = DataciteDoi.active_index_cache_key
    Rails.cache.write(key, "stale-index")

    output = capture_stdout { subject.invoke }

    expect(output).to include("DRIFT")
    expect(output).to include('cached="stale-index"')
    expect(Rails.cache.read(key)).to eq("stale-index")
  end
end
