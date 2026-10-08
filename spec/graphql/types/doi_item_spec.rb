# frozen_string_literal: true

require "rails_helper"

describe DoiItem do
  describe "fields" do
    subject { described_class }

    it { is_expected.to have_field(:id).of_type("ID!") }
    it { is_expected.to have_field(:type).of_type("String!") }
    it { is_expected.to have_field(:creators).of_type("[Creator!]") }
    it { is_expected.to have_field(:titles).of_type("[Title!]") }
    it { is_expected.to have_field(:publicationYear).of_type("Int") }
    it { is_expected.to have_field(:publisher).of_type("Publisher") }
    it { is_expected.to have_field(:subjects).of_type("[Subject!]") }
    it { is_expected.to have_field(:fieldsOfScience).of_type("[FieldOfScience!]") }
    it { is_expected.to have_field(:fieldsOfScienceRepository).of_type("[FieldOfScience!]") }
    it { is_expected.to have_field(:fieldsOfScienceCombined).of_type("[FieldOfScience!]") }
    it { is_expected.to have_field(:dates).of_type("[Date!]") }
    it { is_expected.to have_field(:registered).of_type("ISO8601DateTime") }
    it { is_expected.to have_field(:language).of_type("Language") }
    it { is_expected.to have_field(:identifiers).of_type("[Identifier!]") }
    it { is_expected.to have_field(:types).of_type("ResourceType!") }
    it { is_expected.to have_field(:formats).of_type("[String!]") }
    it { is_expected.to have_field(:sizes).of_type("[String!]") }
    it { is_expected.to have_field(:container).of_type("Container") }
    it { is_expected.to have_field(:version).of_type("String") }
    it { is_expected.to have_field(:rights).of_type("[Rights!]") }
    it { is_expected.to have_field(:descriptions).of_type("[Description!]") }
    it { is_expected.to have_field(:fundingReferences).of_type("[Funding!]") }
    it { is_expected.to have_field(:geolocations).of_type("[Geolocation!]") }
    it { is_expected.to have_field(:url).of_type("Url") }
    it { is_expected.to have_field(:repository).of_type("Repository") }
    it { is_expected.to have_field(:member).of_type("Member") }
    it do
      is_expected.to have_field(:registrationAgency).of_type(
        "RegistrationAgency",
      )
    end
    it { is_expected.to have_field(:formattedCitation).of_type("String") }
    it { is_expected.to have_field(:xml).of_type("String!") }
    it { is_expected.to have_field(:bibtex).of_type("String!") }
    it { is_expected.to have_field(:schemaOrg).of_type("JSON!") }
    it { is_expected.to have_field(:citationCount).of_type("Int") }
    it { is_expected.to have_field(:referenceCount).of_type("Int") }
    it { is_expected.to have_field(:viewCount).of_type("Int") }
    it { is_expected.to have_field(:downloadCount).of_type("Int") }
    it { is_expected.to have_field(:versionCount).of_type("Int") }
    it { is_expected.to have_field(:versionOfCount).of_type("Int") }
    it { is_expected.to have_field(:otherRelatedCount).of_type("Int") }
    it { is_expected.to have_field(:partCount).of_type("Int") }
    it { is_expected.to have_field(:partOfCount).of_type("Int") }
    it { is_expected.to have_field(:citationsOverTime).of_type("[YearTotal!]") }
    it do
      is_expected.to have_field(:viewsOverTime).of_type("[YearMonthTotal!]")
    end
    it do
      is_expected.to have_field(:downloadsOverTime).of_type("[YearMonthTotal!]")
    end
    it do
      is_expected.to have_field(:citations).of_type("WorkConnectionWithTotal")
    end
    it do
      is_expected.to have_field(:references).of_type("WorkConnectionWithTotal")
    end
    it { is_expected.to have_field(:parts).of_type("WorkConnectionWithTotal") }
    it do
      is_expected.to have_field(:part_of).of_type("WorkConnectionWithTotal")
    end
    it do
      is_expected.to have_field(:versions).of_type("WorkConnectionWithTotal")
    end
    it do
      is_expected.to have_field(:version_of).of_type("WorkConnectionWithTotal")
    end
    it do
      is_expected.to have_field(:other_related).of_type("WorkConnectionWithTotal")
    end
  end
end
