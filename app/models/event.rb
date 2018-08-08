class Event
  include Elasticsearch::Model::Proxy
  include Elasticsearch::Persistence::Model

  include Indexable

  # use different index for testing
  index_name Rails.env.test? ? "events-test" : "events"

  attribute :uuid, String, mapping: { type: 'keyword' }
  attribute :subj_id, String, mapping: { type: 'keyword' }
  attribute :obj_id, String, mapping: { type: 'keyword' }
  attribute :doi, String, mapping: { type: 'keyword' }
  attribute :prefix, String, mapping: { type: 'keyword' }
  attribute :subj, String, mapping: { type: 'text' }
  attribute :obj, String, mapping: { type: 'text' }
  attribute :source_id, String, mapping: { type: 'keyword' }
  attribute :source_token, String, mapping: { type: 'keyword' }
  attribute :message_action, String, mapping: { type: 'keyword' }
  attribute :relation_type_id, String, mapping: { type: 'keyword' }
  attribute :access_method, String, mapping: { type: 'keyword' }
  attribute :metric_type, String, mapping: { type: 'keyword' }
  attribute :total, Integer, mapping: { type: 'integer' }
  attribute :license, String, mapping: { type: 'text', fields: { sortable: { type: "keyword" }}}
  attribute :error_messages, String, mapping: { type: 'text' }
  attribute :callback, String, mapping: { type: 'text' }
  attribute :aasm_state, String, mapping: { type: 'keyword' }
  attribute :state_event, String, mapping: { type: 'keyword' }
  attribute :year_month, String, mapping: { type: 'keyword' }
  attribute :created_at, DateTime, mapping: { type: :date }
  attribute :updated_at, DateTime, mapping: { type: :date }
  attribute :indexed_at, DateTime, mapping: { type: :date }
  attribute :occured_at, DateTime, mapping: { type: :date }

  def self.query_fields
    ['subj_id^10', 'obj_id^10', '_all']
  end

  def self.query_aggregations
    {
      year_months: { date_histogram: { field: 'occurred_at', interval: 'month', min_doc_count: 1 } },
      sources: { terms: { field: 'source_id', size: 10, min_doc_count: 1 } },
      prefixes: { terms: { field: 'prefix', size: 10, min_doc_count: 1 } },
      relation_types: { terms: { field: 'relation_type_id', size: 10, min_doc_count: 1 }, aggs: { "total_by_relation_type_id" => { sum: { field: 'total' }}} },
      metric_types: { terms: { field: 'metric_type', size: 10, min_doc_count: 1 } },
      access_methods: { terms: { field: 'access_method', size: 10, min_doc_count: 1 } }
    }
  end
end
