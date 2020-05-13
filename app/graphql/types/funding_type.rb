# frozen_string_literal: true

class FundingType < BaseObject
  description "Information about funding"

  field :funder_name, String, null: true, hash_key: "funderName", description: "Funder name"
  field :funder_identifier, String, null: true, hash_key: "funderIdentifier", description: "Funder identifier"
  field :funder_identifier_type, String, null: true, hash_key: "funderIdentifierType", description: "Funder identifier type"
  field :award_number, String, null: true, hash_key: "awardNumber", description: "Award number"
  field :award_uri, String, null: true, hash_key: "awardUri", description: "Award URI"
  field :award_title, String, null: true, hash_key: "awardTitle", description: "Award title"
end
