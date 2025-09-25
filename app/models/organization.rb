# frozen_string_literal: true

class Organization
  # include helper module for working with Wikidata
  include Wikidatable

  ROR_API_BASE_URL = "https://api.ror.org/v2/organizations"

  MEMBER_ROLES = {
    "ROLE_CONSORTIUM" => "consortium",
    "ROLE_CONSORTIUM_ORGANIZATION" => "consortium_organization",
    "ROLE_ALLOCATOR" => "direct_member",
    "ROLE_FOR_PROFIT_PROVIDER" => "for-profit_provider",
    "ROLE_MEMBER" => "member_only",
  }.freeze

  def self.find_by_id(id)
    ror_id = ror_id_from_url(id)
    return {} if ror_id.blank?

    url = "#{ROR_API_BASE_URL}/#{ror_id}"
    response = Maremma.get(url, host: true, skip_encoding: true)

    return {} if response.status != 200

    message = response.body.fetch("data", {})
    data = [parse_message(message)]

    wikidata = data.dig(0, "wikidata", 0)
    wikidata_data = find_by_wikidata_id(wikidata)
    if wikidata_data
      data = [data.first.reverse_merge(wikidata_data[:data].first)]
    end

    errors = response.body.fetch("errors", nil)

    { data: data, errors: errors }
  end

  def self.find_by_grid_id(id)
    grid_id = grid_id_from_url(id)
    return {} if grid_id.blank?

    url = "#{ROR_API_BASE_URL}?query=\"#{grid_id}\""
    response = Maremma.get(url, host: true, skip_encoding: true)

    message = response.body.dig("data", "items", 0) || {}
    return {} if message.empty?

    data = [parse_message(message)]

    wikidata = data.dig(0, "wikidata", 0)
    wikidata_data = find_by_wikidata_id(wikidata)
    if wikidata_data
      data = [data.first.reverse_merge(wikidata_data[:data].first)]
    end

    errors = response.body.fetch("errors", nil)

    { data: data, errors: errors }
  end

  def self.find_by_crossref_funder_id(id)
    crossref_funder_id = crossref_funder_id_from_url(id)
    return {} if crossref_funder_id.blank?

    url = "#{ROR_API_BASE_URL}?query=\"#{crossref_funder_id.split('/', 2).last}\""
    response = Maremma.get(url, host: true, skip_encoding: true)

    message = response.body.dig("data", "items", 0) || {}
    return {} if message.empty?

    data = [parse_message(message)]

    wikidata = data.dig(0, "wikidata", 0)
    wikidata_data = find_by_wikidata_id(wikidata)
    if wikidata_data
      data = [data.first.reverse_merge(wikidata_data[:data].first)]
    end

    errors = response.body.fetch("errors", nil)

    { data: data, errors: errors }
  end

  def self.query(query, options = {})
    page = options[:offset] || 1
    types = options[:types]
    country = options[:country]

    url = "#{ROR_API_BASE_URL}?page=#{page}"
    url += "&query=#{query}" if query.present?
    if types.present? && country.present?
      url +=
        "&filter=types:#{types.upcase_first},country.country_code:#{
          country.upcase
        }"
    elsif types.present?
      url += "&filter=types:#{types.upcase_first}"
    elsif country.present?
      url += "&filter=country.country_code:#{country.upcase}"
    end

    response = Maremma.get(url, { host: true, skip_encoding: true })

    return {} if response.status != 200

    data =
      Array.wrap(response.body.dig("data", "items")).map do |message|
        parse_message(message)
      end

    countries =
      Array.wrap(response.body.dig("data", "meta", "countries")).map do |hsh|
        country = ISO3166::Country[hsh["id"]]

        {
          "id" => hsh["id"],
          "title" => country.present? ? country.name : hsh["id"],
          "count" => hsh["count"],
        }
      end

    meta = {
      "total" => response.body.dig("data", "number_of_results"),
      "types" => response.body.dig("data", "meta", "types"),
      "countries" => countries,
    }.compact

    errors = response.body.fetch("errors", nil)

    { data: data, meta: meta, errors: errors }
  end

  def self.parse_message(message)
    country = {
      id: message.dig("country", "country_code"),
      name: message.dig("country", "country_name"),
    }.compact

    labels =
      Array.wrap(message["names"])
        .select { |n| n["types"].include?("label") }
        .map do |n|
          code = n["lang"]&.upcase
          { code: code, name: n["value"] }.compact
        end

    # --- external_ids helper ---
    extract_id = ->(type) do
      entry = Array.wrap(message["external_ids"]).find { |eid| eid["type"].casecmp(type).zero? }
      entry&.fetch("all", []) || []
    end

    # remove whitespace from ISNI
    isni = extract_id.call("isni").map { |i| i.delete(" ") }

    # add DOI prefix to Crossref Funder ID
    fundref = extract_id.call("fundref").map { |f| "10.13039/#{f}" }

    wikidata = extract_id.call("wikidata")
    grid     = extract_id.call("grid")

    # --- Links ---
    links =
      Array.wrap(message["links"])
        .select { |l| l["type"] == "website" }
        .map { |l| l["value"] }

    wikipedia_url =
      Array.wrap(message["links"])
        .find { |l| l["type"] == "wikipedia" }&.dig("value")

    Hashie::Mash.new(
      id: message["id"],
      type: "Organization",
      types: message["types"],
      name: Array.wrap(message["names"]).find { |n| n["types"].include?("ror_display") }&.dig("value"),
      aliases: Array.wrap(message["names"]).select { |n| n["types"].include?("alias") }.map { |n| n["value"] },
      acronyms: Array.wrap(message["names"]).select { |n| n["types"].include?("acronym") }.map { |n| n["value"] },
      labels: labels,
      links: links,
      wikipedia_url: wikipedia_url,
      country: country,
      isni: isni,
      fundref: fundref,
      wikidata: wikidata,
      grid: grid,
    )
  end

  def self.ror_id_from_url(url)
    i = Array(%r{\A(https?://)?(ror\.org/)?(0\w{6}\d{2})\z}.match(url)).last
    "ror.org/#{i}" if i.present?
  end

  def self.crossref_funder_id_from_url(url)
    Array(
      %r{\A(https?://)?(dx\.)?(doi.org/)?(doi:)?(10\.13039/.+)\z}.match(
        url,
      ),
    ).
      last
  end

  def self.grid_id_from_url(url)
    Array(%r{\A(https?://)?(grid\.ac/)?(institutes/)?(grid\..+)}.match(url)).
      last
  end
end
