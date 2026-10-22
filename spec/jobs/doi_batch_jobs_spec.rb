# frozen_string_literal: true

require "rails_helper"

describe "DOI batch jobs", type: :job do
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
      total_count: 2,
    )
  end
  let!(:valid_item) do
    batch.items.create!(
      position: 0,
      doi: "10.14454/job-success",
      payload: {
        type: "dois",
        attributes: {
          doi: "10.14454/job-success",
          url: "https://example.org/success",
        },
      },
    )
  end
  let!(:invalid_item) do
    batch.items.create!(
      position: 1,
      doi: "10.14454/job-failure",
      payload: {
        type: "dois",
        attributes: {
          doi: "10.14454/job-failure",
          url: "not-a-url",
        },
      },
    )
  end

  it "fans a batch out in chunks" do
    DoiBatchProcessJob.perform_now(batch.id)

    expect(DoiBatchChunkJob).to have_been_enqueued.with(
      [valid_item.id, invalid_item.id],
    )
    expect(batch.reload.status).to eq("processing")
  end

  it "limits each worker chunk to fifty items" do
    large_batch =
      DoiBatch.create!(
        operation: "create",
        submitted_by: client.symbol.downcase,
        role_id: "client_admin",
        client_id: client.symbol.downcase,
        provider_id: provider.symbol.downcase,
        total_count: 51,
      )
    51.times do |position|
      large_batch.items.create!(
        position: position,
        doi: "10.14454/chunk-#{position}",
        payload: {
          type: "dois",
          attributes: { doi: "10.14454/chunk-#{position}" },
        },
      )
    end

    expect do
      DoiBatchProcessJob.perform_now(large_batch.id)
    end.to have_enqueued_job(DoiBatchChunkJob).exactly(2).times
  end

  it "persists partial success and finalizes exactly once" do
    DoiBatchChunkJob.perform_now([valid_item.id, invalid_item.id])

    expect(valid_item.reload.status).to eq("succeeded")
    expect(valid_item.response_status).to eq(201)
    expect(invalid_item.reload.status).to eq("failed")
    expect(invalid_item.response_status).to eq(422)
    expect(invalid_item.result_errors.first).to include(
      "source" => "url",
    )
    expect(batch.reload).to have_attributes(
      status: "completed",
      succeeded_count: 1,
      failed_count: 1,
    )

    DoiBatchChunkJob.perform_now([valid_item.id, invalid_item.id])
    expect(batch.reload).to have_attributes(
      succeeded_count: 1,
      failed_count: 1,
    )
  end
end
