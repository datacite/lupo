# frozen_string_literal: true

require "rails_helper"

describe DoiBatch do
  subject(:batch) do
    described_class.create!(
      operation: "create",
      submitted_by: "datacite.batch",
      role_id: "client_admin",
      client_id: "datacite.batch",
      total_count: 2,
    )
  end

  it "tracks lifecycle and terminal counters" do
    expect(batch).to have_attributes(
      status: "queued",
      succeeded_count: 0,
      failed_count: 0,
    )

    batch.mark_processing!
    batch.record_item_completion!(successful: true)
    expect(batch.reload).to have_attributes(
      status: "processing",
      succeeded_count: 1,
    )

    batch.record_item_completion!(successful: false)
    expect(batch.reload).to have_attributes(
      status: "completed",
      succeeded_count: 1,
      failed_count: 1,
    )
    expect(batch.completed_at).to be_present
  end

  it "does not increment a completed batch" do
    batch.update!(
      status: "completed",
      succeeded_count: 2,
      completed_at: Time.zone.now,
    )

    batch.record_item_completion!(successful: false)

    expect(batch.reload).to have_attributes(
      succeeded_count: 2,
      failed_count: 0,
    )
  end
end
