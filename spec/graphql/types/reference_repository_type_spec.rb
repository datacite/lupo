
# frozen_string_literal: true

require "rails_helper"

describe ReferenceRepositoryType do
  describe "fields" do
    subject { described_class }

    it { is_expected.to have_field(:id).of_type(!types.ID) }
    it { is_expected.to have_field(:type).of_type("String!") }
    it { is_expected.to have_field(:clientId).of_type(types.ID) }
    it { is_expected.to have_field(:re3dataDoi).of_type(types.ID) }
    it { is_expected.to have_field(:name).of_type("String!") }
    it { is_expected.to have_field(:alternateName).of_type("[String!]") }
    it { is_expected.to have_field(:description).of_type("String") }
    it { is_expected.to have_field(:url).of_type("Url") }
    it { is_expected.to have_field(:re3dataUrl).of_type("Url") }
    it { is_expected.to have_field(:software).of_type("[String!]") }
    it { is_expected.to have_field(:repositoryType).of_type("[String!]") }
    it { is_expected.to have_field(:certificate).of_type("[String!]") }
    it { is_expected.to have_field(:language).of_type("[String!]") }
    it { is_expected.to have_field(:providerType).of_type("[String!]") }
    it { is_expected.to have_field(:pidSystem).of_type("[String!]") }
    it { is_expected.to have_field(:dataAccess).of_type("[TextRestriction!]") }
    it { is_expected.to have_field(:dataUpload).of_type("[TextRestriction!]") }
    it { is_expected.to have_field(:contact).of_type("[String!]") }
    it { is_expected.to have_field(:subject).of_type("[DefinedTerm!]") }

  end


  #describe "find reference_repository", elastic: true, vcr: true do
    #let!(:client) { create(:client) }
  #end
end
