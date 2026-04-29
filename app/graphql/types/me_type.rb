# frozen_string_literal: true

class MeType < BaseObject
  description "Information about the logged-in user"

  field :id, ID, null: false, description: "User identifier."

  def id
    object.is_a?(Hash) ? object["uid"] : object.uid
  end

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
