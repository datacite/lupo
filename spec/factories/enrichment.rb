# frozen_string_literal: true

FactoryBot.define do
  factory :enrichment do
    doi { create(:doi, doi: "10.0000/fake.test.doi", agency: "datacite") }
  end
end
