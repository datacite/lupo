# frozen_string_literal: true

class DoiBatch < ApplicationRecord
  OPERATIONS = %w[create update].freeze
  STATUSES = %w[queued processing completed].freeze

  before_validation :set_defaults

  validates :uuid, presence: true, uniqueness: true
  validates :operation, inclusion: { in: OPERATIONS }
  validates :status, inclusion: { in: STATUSES }
  validates :submitted_by, :role_id, presence: true
  validates :total_count, :succeeded_count, :failed_count,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  has_many :items,
           -> { order(:position) },
           class_name: "DoiBatchItem",
           dependent: :delete_all,
           inverse_of: :doi_batch

  def mark_processing!
    with_lock do
      next if completed?

      update!(status: "processing", started_at: started_at || Time.zone.now)
    end
  end

  def record_item_completion!(successful:)
    with_lock do
      return if completed?

      updates =
        if successful
          { succeeded_count: succeeded_count + 1 }
        else
          { failed_count: failed_count + 1 }
        end

      terminal_count = updates.fetch(:succeeded_count, succeeded_count) +
        updates.fetch(:failed_count, failed_count)

      if terminal_count >= total_count
        updates[:status] = "completed"
        updates[:completed_at] = Time.zone.now
      else
        updates[:status] = "processing"
        updates[:started_at] = started_at || Time.zone.now
      end

      update!(updates)
    end
  end

  def queued?
    status == "queued"
  end

  def processing?
    status == "processing"
  end

  def completed?
    status == "completed"
  end

  private
    def set_defaults
      self.uuid ||= SecureRandom.uuid
      self.status ||= "queued"
    end
end
