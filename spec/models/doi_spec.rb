require 'rails_helper'

describe Doi, type: :model, vcr: true do
  it { should validate_presence_of(:doi) }

  describe "state" do
    subject { FactoryBot.create(:doi) }

    describe "draft" do
      it "defaults to draft" do
        expect(subject).to have_state(:draft)
      end
    end

    describe "registered" do
      it "can register" do
        subject.register
        expect(subject).to have_state(:registered)
      end

      it "can't register with test prefix" do
        subject = FactoryBot.create(:doi, doi: "10.5072/x")
        subject.register
        expect(subject).to have_state(:draft)
      end
    end

    describe "findable" do
      it "can publish" do
        subject.publish
        expect(subject).to have_state(:findable)
      end

      it "can't register with test prefix" do
        subject = FactoryBot.create(:doi, doi: "10.5072/x")
        subject.publish
        expect(subject).to have_state(:draft)
      end
    end

    describe "flagged" do
      it "can flag" do
        subject.register
        subject.flag
        expect(subject).to have_state(:flagged)
      end

      it "can't flag if draft" do
        subject.flag
        expect(subject).to have_state(:draft)
      end
    end

    describe "broken" do
      it "can link_check" do
        subject.register
        subject.link_check
        expect(subject).to have_state(:broken)
      end

      it "can't link_check if draft" do
        subject.link_check
        expect(subject).to have_state(:draft)
      end
    end
  end
end
