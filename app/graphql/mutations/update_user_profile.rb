# frozen_string_literal: true

class UpdateUserProfile < BaseMutation
  argument :uid, ID, required: true
  argument :name, String, required: false

  field :user, UserType, null: true
  field :errors, [ErrorType], null: false

  def resolve(uid: nil)
    if uid.blank? || context[:current_user].blank?
      return { user: nil, errors: [] }
    end

    # Use DataCite users API to update user profile
    data = {
      "users" => {
        "id" => context[:current_user].uid,
        "attributes" => {
          "name" => name
        }
      },
    }

    api_url =
      if Rails.env.production?
        "https://api.datacite.org"
      else
        "https://api.stage.datacite.org"
      end
    url = "#{api_url}/users"
    response =
      Maremma.post(
        url,
        data: data.to_json,
        content_type: "application/json;charset=UTF-8",
        bearer: context[:current_user].jwt,
      )

    if response.status == 200
      user =
        OpenStruct.new(
          uid: response.body.dig("data", "id"),
          type: "user",
          name: response.body.dig("data", "attributes", "name"),
        )

      { user: user, errors: [] }
    else
      errors =
        if response.body["errors"].present?
          ": " + response.body.dig("errors", 0, "title")
        else
          ""
        end
      Rails.logger.error "Error updating name for user #{
                           context[:current_user].uid
                         } " +
        errors
      { user: nil, errors: response.body["errors"] }
    end
  end
end
