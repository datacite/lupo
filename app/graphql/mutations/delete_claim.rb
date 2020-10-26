class DeleteClaim < BaseMutation
  argument :id, ID, required: true

  field :message, String, null: false
  field :errors, [ErrorType], null: false

  def resolve(id: nil)
    return { claim: nil, errors: [] } if id.blank? || context[:current_user].blank?

    # Use DataCite Claims API call to delete claim
    api_url = Rails.env.production? ? "https://api.datacite.org" : "https://api.stage.datacite.org"
    url = "#{api_url}/claims/#{id}"
    response = Maremma.delete(url, bearer: context[:current_user].jwt)

    if [200, 204].include?(response.status)
      {
        message: "Claim #{id} deleted.",
        errors: []
      }
    else
      errors = response.body["errors"].present? ? ": " + response.body.dig("errors", 0, "title") : ""
      Rails.logger.error "Error deleting claim id #{id} for user #{context[:current_user].uid}" + errors
      {
        message: "Error deleting claim #{id}.",
        errors: response.body["errors"]
      }
    end
  end
end
