# frozen_string_literal: true

class DataDump < ApplicationRecord
  include Elasticsearch::Model

  include Indexable
  include AASM

  validates_presence_of :uid
  validates_presence_of :scope
  validates_presence_of :start_date
  validates_presence_of :end_date

  validates_uniqueness_of :uid, message: "This Data Dump UID is already in use"

  validates_inclusion_of :scope, in: %w(metadata link), allow_blank: false

  aasm whiny_transitions: false do
    # initial state should prevent public visibility
    state :generating, initial: true
    # we might add more here in the future depending on the granularity of status updates we wish to provide
    # but for now, we have a state for when the dump is done and being transferred to S3 and one for when it is
    # ready to be downloaded
    state :storing, :complete

    event :store do
      transitions from: :generating, to: :storing
    end

    event :release do
      transitions from: :storing, to: :complete
    end
  end

  if Rails.env.test?
    index_name "data-dumps-test#{ENV['TEST_ENV_NUMBER']}"
  elsif ENV["ES_PREFIX"].present?
    index_name "data-dumps-#{ENV['ES_PREFIX']}"
  else
    index_name "data-dumps"
  end

  settings index: {
    number_of_shards: 1,
    analysis: {
      analyzer: {
        string_lowercase: {
          tokenizer: "keyword", filter: %w[lowercase]
        },
      },
      normalizer: {
        keyword_lowercase: { type: "custom", filter: %w[lowercase] },
      },
    },
  } do
    mapping dynamic: "false" do
      indexes :id
      indexes :uid, type: :text
      indexes :scope, type: :keyword
      indexes :description, type: :text
      indexes :start_date, type: :date, format: :date_optional_time
      indexes :end_date, type: :date, format: :date_optional_time
      indexes :records, type: :integer
      indexes :checksum, type: :text
      indexes :file_path, type: :text
      indexes :aasm_state, type: :keyword
      indexes :created_at, type: :date, format: :date_optional_time,
              fields: {
                created_sort: { type: :date }
              }
      indexes :updated_at, type: :date, format: :date_optional_time,
              fields: {
                updated_sort: { type: :date }
              }
    end
  end

  def self.query_aggregations
    {}
  end
end
