# frozen_string_literal: true

class DoiBatchSerializer
  include JSONAPI::Serializer

  set_key_transform :camel_lower
  set_type :"doi-batches"
  set_id :uuid

  attributes :operation,
             :status,
             :total_count,
             :succeeded_count,
             :failed_count,
             :started_at,
             :completed_at,
             :created_at,
             :updated_at

  attribute :pending_count do |batch|
    batch.total_count - batch.succeeded_count - batch.failed_count
  end
end
