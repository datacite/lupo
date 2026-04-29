# frozen_string_literal: true

class FundingType < BaseObject
  description "Information about funding"

  field :funder_name,
        String,
        null: true, description: "Funder name"

  def funder_name
    object["funderName"]
  end

  field :funder_identifier,
        String,
        null: true,
        description: "Funder identifier"

  def funder_identifier
    object["funderIdentifier"]
  end

  field :funder_identifier_type,
        String,
        null: true,
        description: "Funder identifier type"

  def funder_identifier_type
    object["funderIdentifierType"]
  end

  field :award_number,
        String,
        null: true, description: "Award number"

  def award_number
    object["awardNumber"]
  end

  field :award_uri,
        String,
        null: true, description: "Award URI"

  def award_uri
    object["awardUri"]
  end

  field :award_title,
        String,
        null: true, description: "Award title"

  def award_title
    object["awardTitle"]
  end
end
