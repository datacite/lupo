# frozen_string_literal: true

class LinkType < BaseObject
  description "Information about links"

  field :name, String, null: true, description: "Name for the link."
  field :url, Url, null: true, description: "URL for the link."
end
