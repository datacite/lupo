# frozen_string_literal: true

class DoiBatchItem < ApplicationRecord
  STATUSES = %w[queued processing succeeded failed].freeze
  TERMINAL_STATUSES = %w[succeeded failed].freeze

  belongs_to :doi_batch, inverse_of: :items

  validates :position,
            presence: true,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 },
            uniqueness: { scope: :doi_batch_id }
  validates :payload, presence: true
  validates :status, inclusion: { in: STATUSES }

  scope :by_cursor, ->(position) { where("position > ?", position) }
  scope :with_status, ->(status) { where(status: status) if status.present? }

  def terminal?
    status.in?(TERMINAL_STATUSES)
  end

  def succeeded?
    status == "succeeded"
  end

  def failed?
    status == "failed"
  end
end
