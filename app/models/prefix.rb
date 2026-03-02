# frozen_string_literal: true

class Prefix < ApplicationRecord
  # include helper module for caching infrequently changing resources
  include Cacheable

  # include helper module for Elasticsearch
  include Indexable

  # include helper module for Prefix registration
  include Identifiable

  include Elasticsearch::Model

  validates_presence_of :uid
  validates_uniqueness_of :uid
  validates_format_of :uid, with: /\A10\.\d{4,9}\z/

  has_many :client_prefixes, dependent: :destroy
  has_many :clients, through: :client_prefixes
  has_many :provider_prefixes, dependent: :destroy
  has_many :providers, through: :provider_prefixes

  # use different index for testing
  if Rails.env.test?
    index_name "prefixes-test#{ENV['TEST_ENV_NUMBER']}"
  elsif ENV["ES_PREFIX"].present?
    index_name "prefixes-#{ENV['ES_PREFIX']}"
  else
    index_name "prefixes"
  end

  mapping dynamic: "false" do
    indexes :id, type: :keyword
    indexes :uid, type: :keyword
    indexes :provider_ids, type: :keyword
    indexes :client_ids, type: :keyword
    indexes :provider_prefix_ids, type: :keyword
    indexes :client_prefix_ids, type: :keyword
    indexes :state, type: :keyword
    indexes :prefix, type: :text
    indexes :created_at, type: :date

    # index associations
    indexes :clients, type: :object
    indexes :providers, type: :object
    indexes :client_prefixes, type: :object
    indexes :provider_prefixes, type: :object
  end

  def as_indexed_json(_options = {})
    {
      "id" => uid,
      "uid" => uid,
      "provider_ids" => provider_ids,
      "client_ids" => client_ids,
      "provider_prefix_ids" => provider_prefix_ids,
      "client_prefix_ids" => client_prefix_ids,
      "state" => state,
      "prefix" => prefix,
      "created_at" => created_at.try(:iso8601),
      "clients" =>
        clients.map { |m| m.try(:as_indexed_json, exclude_associations: true) },
      "providers" =>
        providers.map do |m|
          m.try(:as_indexed_json, exclude_associations: true)
        end,
      "client_prefixes" =>
        client_prefixes.map do |m|
          m.try(:as_indexed_json, exclude_associations: true)
        end,
      "provider_prefixes" =>
        provider_prefixes.map do |m|
          m.try(:as_indexed_json, exclude_associations: true)
        end,
    }
  end

  def self.query_aggregations
    {
      states: { terms: { field: "state", size: 3, min_doc_count: 1 } },
      years: {
        date_histogram: {
          field: "created_at",
          interval: "year",
          format: "year",
          order: { _key: "desc" },
          min_doc_count: 1,
        },
        aggs: { bucket_truncate: { bucket_sort: { size: 10 } } },
      },
      providers: {
        terms: { field: "provider_ids_and_names", size: 10, min_doc_count: 1 },
      },
      clients: {
        terms: { field: "client_ids_and_names", size: 10, min_doc_count: 1 },
      },
    }
  end

  # return results for one prefix
  def self.find_by_id(id)
    __elasticsearch__.search(
      query: { term: { uid: id } }, aggregations: query_aggregations,
    )
  end

  def self.get_registration_agency
    headers = [
      "Prefix",
      "RA",
    ]

    rows = Prefix.all.pluck(:uid).reduce([]) do |sum, prefix|
      ra = get_doi_ra(prefix).to_s.downcase

      if ra != "datacite"
        row = {
          prefix: prefix,
          ra: ra,
        }.values

        sum << CSV.generate_line(row)
      end

      sum
    end

    csv = [CSV.generate_line(headers)] + rows
    csv.join("")
  end

  def client_ids
    clients.pluck(:symbol).map(&:downcase)
  end

  def client_ids_and_name
    clients.pluck(:symbol, :name).map { |p| "#{p[0].downcase}:#{p[1]}" }
  end

  def provider_ids
    providers.pluck(:symbol).map(&:downcase)
  end

  def provider_ids_and_names
    providers.pluck(:symbol, :name).map { |p| "#{p[0].downcase}:#{p[1]}" }
  end

  def client_prefix_ids
    client_prefixes.pluck(:uid)
  end

  def provider_prefix_ids
    provider_prefixes.pluck(:uid)
  end

  def prefix
    uid
  end

  def state
    if client_prefix_ids.present?
      "with-repository"
    elsif provider_prefix_ids.present?
      "without-repository"
    else
      "unassigned"
    end
  end
end
