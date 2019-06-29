class Researcher < ActiveRecord::Base
  # include helper module for Elasticsearch
  include Indexable

  include Elasticsearch::Model

  validates_presence_of :uid
  validates_uniqueness_of :uid
  validates_format_of :email, with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i, if: :email?
  
  # use different index for testing
  index_name Rails.env.test? ? "researchers-test" : "researchers"

  settings index: {
    analysis: {
      analyzer: {
        string_lowercase: { tokenizer: 'keyword', filter: %w(lowercase ascii_folding) }
      },
      filter: { ascii_folding: { type: 'asciifolding', preserve_original: true } }
    }
  } do
    mapping dynamic: 'false' do
      indexes :id,            type: :keyword
      indexes :uid,           type: :keyword
      indexes :name,          type: :text, fields: { keyword: { type: "keyword" }, raw: { type: "text", "analyzer": "string_lowercase", "fielddata": true }}
      indexes :given_names,   type: :text, fields: { keyword: { type: "keyword" }, raw: { type: "text", "analyzer": "string_lowercase", "fielddata": true }}
      indexes :family_name,   type: :text, fields: { keyword: { type: "keyword" }, raw: { type: "text", "analyzer": "string_lowercase", "fielddata": true }}
      indexes :created_at,    type: :date
      indexes :updated_at,    type: :date
    end
  end

  # also index id as workaround for finding the correct key in associations
  def as_indexed_json(options={})
    {
      "id" => uid,
      "uid" => uid,
      "name" => name,
      "given_names" => given_names,
      "family_name" => family_name,
      "created_at" => created_at,
      "updated_at" => updated_at
    }
  end

  def self.query_fields
    ['uid^10', 'name^5', 'given_names^5', 'family_name^5', '_all']
  end

  def self.query_aggregations
    {}
  end

  # return results for one or more ids
  def self.find_by_id(ids, options={})
    ids = ids.split(",") if ids.is_a?(String)
    
    options[:page] ||= {}
    options[:page][:number] ||= 1
    options[:page][:size] ||= 1000
    options[:sort] ||= { created_at: { order: "asc" }}

    __elasticsearch__.search({
      from: (options.dig(:page, :number) - 1) * options.dig(:page, :size),
      size: options.dig(:page, :size),
      sort: [options[:sort]],
      query: {
        terms: {
          uid: ids
        }
      },
      aggregations: query_aggregations
    })
  end
end
