class CreateClaim < BaseMutation
  argument :doi, ID, required: true
  argument :id, ID, required: false
  argument :source_id, String, required: false

  field :claim, ClaimType, null: true
  field :errors, [ErrorType], null: false

  def resolve(doi: nil, id: nil, source_id: nil)
    return { claim: nil, errors: [] } if doi.blank? || context[:current_user].blank?

    # Use DataCite Claims API call to post claim
    data = { 
      "claim" => { "uuid" => id || SecureRandom.uuid,
                   "orcid" => context[:current_user].uid,
                   "doi" => doi,
                   "claim_action" => "create",
                   "source_id" => source_id || "orcid_update" } }

    api_url = Rails.env.production? ? "https://api.datacite.org" : "https://api.stage.datacite.org"
    url = "#{api_url}/claims"
    response = Maremma.post(url, data: data.to_json, content_type: "application/json;charset=UTF-8", bearer: context[:current_user].jwt)

    if response.status == 202
      claim = OpenStruct.new(
        id: response.body.dig("data", "id"),
        type: "claim",
        orcid: response.body.dig("data", "attributes", "orcid"),
        source_id: response.body.dig("data", "attributes", "sourceId"),
        state: response.body.dig("data", "attributes", "state"),
        claim_action: response.body.dig("data", "attributes", "claimAction"),
        claimed: response.body.dig("data", "attributes", "claimed"),
        error_messages: response.body.dig("data", "attributes", "errorMessages"))

      {
        claim: claim,
        errors: []
      }
    else
      errors = response.body["errors"].present? ? ": " + response.body.dig("errors", 0, "title") : ""
      Rails.logger.error "Error creating claim for user #{context[:current_user].uid} and doi #{doi}" + errors
      {
        claim: nil,
        errors: response.body["errors"]
      }
    end
  end
end
