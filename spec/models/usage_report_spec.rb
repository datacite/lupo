# frozen_string_literal: true

require "rails_helper"

describe UsageReport, type: :model, vcr: true do
  describe "find_by_id" do
    it "found" do
      id = "https://api.test.datacite.org/reports/0498876e-dd55-42b0-b2a6-850df004a0e4"
      usage_reports = UsageReport.find_by_id(id)
      expect(usage_reports[:data].size).to eq(1)
      expect(usage_reports[:data].first).to eq(:id=>"https://api.test.datacite.org/reports/0498876e-dd55-42b0-b2a6-850df004a0e4", :reporting_period=>{:begin_date=>"2018-10-01", :end_date=>"2018-10-31"})
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
      expect(usage_reports.dig(:meta, "total")).to eq(116)
      expect(usage_reports[:data].size).to eq(25)
      expect(usage_reports[:data].first).to eq(:id=>"https://api.test.datacite.org/reports/0498876e-dd55-42b0-b2a6-850df004a0e4", :reporting_period=>{:begin_date=>"2018-10-01", :end_date=>"2018-10-31"})
    end

    it "size" do
      query = nil
      usage_reports = UsageReport.query(query, page: { number: 1, size: 10})
      expect(usage_reports.dig(:meta, "total")).to eq(116)
      expect(usage_reports[:data].size).to eq(10)
      expect(usage_reports[:data].first).to eq(:id=>"https://api.test.datacite.org/reports/0498876e-dd55-42b0-b2a6-850df004a0e4", :reporting_period=>{:begin_date=>"2018-10-01", :end_date=>"2018-10-31"})
    end
  end
end
