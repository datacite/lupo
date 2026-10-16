# frozen_string_literal: true

require "rails_helper"

describe DoiMutation do
  let(:provider) { create(:provider, symbol: "DATACITE") }
  let(:client) { create(:client, provider: provider, symbol: "DATACITE.BATCH") }
  let(:prefix) { create(:prefix, uid: "10.14454") }
  let!(:client_prefix) { create(:client_prefix, client: client, prefix: prefix) }
  let(:batch) do
    DoiBatch.create!(
      operation: "create",
      submitted_by: client.symbol.downcase,
      role_id: "client_admin",
      client_id: client.symbol.downcase,
      provider_id: provider.symbol.downcase,
      total_count: 1,
    )
  end
  let(:actor) { DoiBatchActor.new(batch) }
  let(:ability) { Ability.new(actor) }
  let(:authorizer) do
    ->(action, resource) { ability.authorize!(action, resource) }
  end

  it "creates through the same authorization and callback path" do
    result =
      described_class.new(
        operation: "create",
        attributes: {
          doi: "10.14454/service-create",
          url: "https://example.org/create",
          client_id: client.symbol,
        },
        actor: actor,
        authorizer: authorizer,
      ).call

    expect(result).to be_success
    expect(result.status).to eq(:created)
    expect(result.doi).to be_persisted
  end

  it "updates an existing DOI and upserts a missing DOI" do
    doi =
      create(
        :doi,
        type: "DataciteDoi",
        client: client,
        doi: "10.14454/service-update",
      )

    update_result =
      described_class.new(
        operation: "update",
        id: doi.doi,
        attributes: {
          url: "https://example.org/updated",
          client_id: client.symbol,
        },
        actor: actor,
        authorizer: authorizer,
      ).call
    upsert_result =
      described_class.new(
        operation: "update",
        id: "10.14454/service-upsert",
        attributes: {
          url: "https://example.org/upsert",
          client_id: client.symbol,
        },
        actor: actor,
        authorizer: authorizer,
      ).call

    expect(update_result).to be_success
    expect(update_result.status).to eq(:ok)
    expect(doi.reload.url).to eq("https://example.org/updated")
    expect(upsert_result).to be_success
    expect(upsert_result.status).to eq(:created)
  end
end
