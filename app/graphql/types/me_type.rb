# frozen_string_literal: true

class MeType < BaseObject
  description "Information about the logged-in user"

  field :id, ID, null: false, hash_key: "uid", description: "User identifier."
  field :type, String, null: false, description: "Type."
  field :name, String, null: false, description: "User name."
  field :beta_tester, Boolean, null: false, description: "Beta tester status."

  def type
    "CurrentUser"
  end

  def beta_tester
    object.beta_tester.present?
  end
end
