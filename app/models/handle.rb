# frozen_string_literal: true

class Handle
  include Searchable

  attr_reader :id,
              :prefix,
              :registration_agency,
              :clients,
              :providers,
              :created,
              :cache_key,
              :updated

  RA_HANDLES = {
    "10.SERV/CROSSREF" => "Crossref",
    "10.SERV/DEFAULT" => "Crossref",
    "10.SERV/DATACITE" => "DataCite",
    "10.SERV/ETH" => "DataCite",
    "10.SERV/EIDR" => "EIDR",
    "10.SERV/KISTI" => "KISTI",
    "10.SERV/MEDRA" => "mEDRA",
    "10.SERV/ISTIC" => "ISTIC",
    "10.SERV/JALC" => "JaLC",
    "10.SERV/AIRITI" => "Airiti",
    "10.SERV/CNKI" => "CNKI",
    "10.SERV/OP" => "OP",
  }.freeze

  def initialize(attributes, _options = {})
    @id = attributes.fetch("id").underscore.dasherize
    @prefix = @id
    @registration_agency = attributes.fetch("registration_agency", nil)
    @updated = attributes.fetch("updated", nil)
  end

  def cache_key
    "handles/#{id}-#{updated}"
  end

  def client_ids
    []
  end

  def provider_ids
    []
  end

  def self.get_query_url(options = {})
    options[:id].present? ? "#{url}/#{options[:id]}" : url
  end

  def self.parse_data(result, options = {})
    return nil if result.blank? || result["errors"]

    if options[:id]
      response_code = result.body.dig("data", "responseCode")
      return nil unless response_code == 1

      record =
        result.body.fetch("data", {}).fetch("values", []).detect do |hs|
          hs["type"] == "HS_SERV"
        end

      fail ActiveRecord::RecordNotFound if record.blank?

      ra = record.dig("data", "value")

      item = {
        "id" => result.body.dig("data", "handle"),
        "registration_agency" => RA_HANDLES[ra] || ra || "unknown",
        "updated" => record.fetch("timestamp", nil),
      }

      parse_item(item)
    end
  end

  def self.url
    "https://doi.org/api/handles"
  end
end
