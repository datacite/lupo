require 'rails_helper'

describe Doi, vcr: true do
  subject { create(:doi) }

  context "validate_prefix" do
    it 'should validate' do
      str = "10.5072"
      expect(subject.validate_prefix(str)).to eq("10.5072")
    end

    it 'should validate with slash' do
      str = "10.5072/"
      expect(subject.validate_prefix(str)).to eq("10.5072")
    end

    it 'should validate with shoulder' do
      str = "10.5072/FK2"
      expect(subject.validate_prefix(str)).to eq("10.5072")
    end

    it 'should not validate if not DOI prefix' do
      str = "20.5072"
      expect(subject.validate_prefix(str)).to be_nil
    end
  end

  context "generate_random_doi" do
    it 'should generate' do
      str = "10.5072"
      expect(subject.generate_random_doi(str).length).to eq(17)
    end

    it 'should generate with seed' do
      str = "10.5072"
      number = 123456
      expect(subject.generate_random_doi(str, number: number)).to eq("10.5072/003r-j076")
    end

    it 'should generate with seed checksum' do
      str = "10.5072"
      number = 1234578
      expect(subject.generate_random_doi(str, number: number)).to eq("10.5072/015n-mj18")
    end

    it 'should generate with another seed checksum' do
      str = "10.5072"
      number = 1234579
      expect(subject.generate_random_doi(str, number: number)).to eq("10.5072/015n-mk15")
    end

    it 'should generate with shoulder' do
      str = "10.5072/fk2"
      number = 123456
      expect(subject.generate_random_doi(str, number: number)).to eq("10.5072/fk2-003r-j076")
    end

    it 'should not generate if not DOI prefix' do
      str = "20.5438"
      expect { subject.generate_random_doi(str) }.to raise_error(IdentifierError, "No valid prefix found")
    end
  end
end
