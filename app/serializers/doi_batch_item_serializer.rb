# frozen_string_literal: true

class DoiBatchItemSerializer
  include JSONAPI::Serializer

  set_key_transform :camel_lower
  set_type :"doi-batch-items"
  set_id do |item|
    item.position.to_s
  end

  attributes :position,
             :status,
             :response_status,
             :started_at,
             :completed_at

  attribute :errors, &:result_errors

  attribute :doi do |item|
    item.doi&.downcase
  end

  link :doi do |item|
    if item.succeeded? && item.doi.present?
      "#{ENV['REST_URL']}/dois/#{item.doi.downcase}"
    end
  end
end
