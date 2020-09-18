# frozen_string_literal: true

class MemberRoleType < BaseObject
  description "Information about the membership role."

  field :id, ID, null: true, description: "Role ID"
  field :name, String, null: true, description: "Role name"
end
