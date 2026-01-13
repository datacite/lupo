# frozen_string_literal: true

require "rails_helper"

describe PreloadedEventRelation do
  let(:event1) { double("Event", id: 1, target_doi: "10.1234/TEST1", source_doi: "10.1234/TEST2", total: 10) }
  let(:event2) { double("Event", id: 2, target_doi: "10.1234/TEST2", source_doi: "10.1234/TEST3", total: 20) }
  let(:event3) { double("Event", id: 3, target_doi: "10.1234/TEST1", source_doi: nil, total: 30) }
  let(:events) { [event1, event2, event3] }
  let(:relation) { PreloadedEventRelation.new(events) }

  describe "#pluck" do
    it "plucks a single column" do
      expect(relation.pluck(:id)).to eq([1, 2, 3])
      expect(relation.pluck(:total)).to eq([10, 20, 30])
    end

    it "plucks multiple columns" do
      result = relation.pluck(:id, :total)
      expect(result).to eq([[1, 10], [2, 20], [3, 30]])
    end

    it "handles nil values" do
      expect(relation.pluck(:source_doi)).to eq(["10.1234/TEST2", "10.1234/TEST3", nil])
    end
  end

  describe "#map" do
    it "maps over events" do
      result = relation.map { |e| e.id * 2 }
      expect(result).to eq([2, 4, 6])
    end
  end

  describe "#select" do
    it "filters events and returns PreloadedEventRelation" do
      result = relation.select { |e| e.total > 15 }
      expect(result).to be_a(PreloadedEventRelation)
      expect(result.to_a).to eq([event2, event3])
    end
  end

  describe "#compact" do
    let(:events_with_nils) { [event1, nil, event2] }
    let(:relation_with_nils) { PreloadedEventRelation.new(events_with_nils) }

    it "removes nil values" do
      result = relation_with_nils.compact
      expect(result).to be_a(PreloadedEventRelation)
      expect(result.to_a).to eq([event1, event2])
    end
  end

  describe "#uniq" do
    let(:duplicate_events) { [event1, event1, event2] }
    let(:relation_with_dups) { PreloadedEventRelation.new(duplicate_events) }

    it "removes duplicate events" do
      result = relation_with_dups.uniq
      expect(result).to be_a(PreloadedEventRelation)
      expect(result.to_a).to eq([event1, event2])
    end
  end

  describe "#sort_by" do
    it "sorts events" do
      result = relation.sort_by(&:total)
      expect(result).to be_a(PreloadedEventRelation)
      expect(result.to_a.map(&:total)).to eq([10, 20, 30])
    end
  end

  describe "#group_by" do
    it "groups events" do
      result = relation.group_by { |e| e.target_doi }
      expect(result.keys).to include("10.1234/TEST1", "10.1234/TEST2")
      expect(result["10.1234/TEST1"].length).to eq(2)
    end
  end

  describe "#inject" do
    it "reduces events" do
      result = relation.inject(0) { |sum, e| sum + e.total }
      expect(result).to eq(60)
    end
  end

  describe "#length" do
    it "returns the number of events" do
      expect(relation.length).to eq(3)
    end
  end

  describe "#empty?" do
    it "returns false when events exist" do
      expect(relation.empty?).to be false
    end

    it "returns true when no events" do
      empty_relation = PreloadedEventRelation.new([])
      expect(empty_relation.empty?).to be true
    end
  end

  describe "#present?" do
    it "returns true when events exist" do
      expect(relation.present?).to be true
    end

    it "returns false when no events" do
      empty_relation = PreloadedEventRelation.new([])
      expect(empty_relation.present?).to be false
    end
  end

  describe "#blank?" do
    it "returns false when events exist" do
      expect(relation.blank?).to be false
    end

    it "returns true when no events" do
      empty_relation = PreloadedEventRelation.new([])
      expect(empty_relation.blank?).to be true
    end
  end

  describe "#to_a" do
    it "returns the underlying array" do
      expect(relation.to_a).to eq(events)
    end
  end

  describe "Enumerable methods" do
    it "implements each" do
      collected = []
      relation.each { |e| collected << e.id }
      expect(collected).to eq([1, 2, 3])
    end

    it "works with Enumerable methods" do
      expect(relation.first).to eq(event1)
      expect(relation.last).to eq(event3)
      expect(relation.count).to eq(3)
    end
  end
end
