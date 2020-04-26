# frozen_string_literal: true

class Types::IssnType < Types::BaseObject
  description "Information about ISSN"

  field :issnl, String, null: true, description: "The ISSNL"
  field :electronic, String, null: true, description: "The electronic ISSN"
  field :print, String, null: true, description: "The print ISSN"
end
