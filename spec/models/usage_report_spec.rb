# frozen_string_literal: true

require "rails_helper"

describe UsageReport, type: :model, vcr: true do
  describe "find_by_id" do
    it "found" do
      id = "073f27b5-d38b-4301-ab73-3274ba3eb672"
      usage_reports = UsageReport.find_by_id(id)
      expect(usage_reports[:data].size).to eq(1)
      puts usage_reports[:data].first
      expect(usage_reports[:data].first).to eq(:id=>"073f27b5-d38b-4301-ab73-3274ba3eb672", :reporting_period=>{:begin_date=>"2019-05-01", :end_date=>"2019-05-15"})
    end

    it "not found" do
      id = "xxx"
      funder = UsageReport.find_by_id(id)
      expect(funder).to be_empty
    end
  end

  describe "query" do
    it "all" do
      query = nil
      usage_reports = UsageReport.query(query, page: { number: 1, size: 25})
      expect(usage_reports.dig(:meta, "total")).to eq(50)
      expect(usage_reports[:data].size).to eq(25)
      expect(usage_reports[:data].first).to eq(:id=>"073f27b5-d38b-4301-ab73-3274ba3eb672", :reporting_period=>{:begin_date=>"2019-05-01", :end_date=>"2019-05-15"})
    end

    it "size" do
      query = nil
      usage_reports = UsageReport.query(query, page: { number: 1, size: 10})
      expect(usage_reports.dig(:meta, "total")).to eq(50)
      expect(usage_reports[:data].size).to eq(10)
      expect(usage_reports[:data].first).to eq(:id=>"073f27b5-d38b-4301-ab73-3274ba3eb672", :reporting_period=>{:begin_date=>"2019-05-01", :end_date=>"2019-05-15"})
    end
  end
end
