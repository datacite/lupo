class ResolutionReport < ApplicationRecord
  validates :period, presence: true, format: {
    with: /\A\d{4}-(0[1-9]|1[0-2])\z/,
    message: "must be in YYYY-MM format (e.g., 2026-08)"
  }
  validates :prefix, presence: true, length: { maximum: 80 }

  validates :total_attempted_resolutions,
            :successful_resolutions,
            :failed_resolutions,
            :total_unique_dois,
            :unique_doi_successes,
            :unique_doi_failures,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  validates :prefix,
          presence: true,
          length: { maximum: 80 },
          uniqueness: {
            scope: :period,
            case_sensitive: false,
            message: "already has a report for this period"
          }

  scope :chronological, -> { order(period: :asc, prefix: :asc) }
  scope :newest_first, -> { order(period: :desc, prefix: :asc) }

  # Converts "2026-08" -> "202608"
  def compact_period
    period&.delete("-")
  end

  # Converts "202608" -> "2026-08" (leaves "2026-08" unchanged if already formatted)
  def self.format_period(raw_period)
    return nil if raw_period.blank?

    str = raw_period.to_s.strip
    return "#{str[0, 4]}-#{str[4, 2]}" if str.match?(/\A\d{6}\z/)

    str
  end

  def formatted_period(format = "%B %Y")
    Date.strptime(period, "%Y-%m").strftime(format)
  end
end
