# frozen_string_literal: true

class DataCatalog
  # include helper module for PORO models
  include Modelable

  def self.find_by_id(id)
    doi = doi_from_url(id)
    return {} if doi.blank?

    url = "https://api.datacite.org/re3data/#{doi}"
    response = Maremma.get(url, host: true, skip_encoding: true)

    if response.status != 200 || response.body.dig("data", "id") != doi.upcase
      return {}
    end

    message = response.body.dig("data", "attributes")
    data = [parse_message(id: id, message: message)]

    errors = response.body.fetch("errors", nil)

    { data: data, errors: errors }
  end

  def self.query(query, options = {})
    limit = options[:limit] || 25
    page = options[:offset] || 1

    params = {
      query: query,
      subject: options[:subject],
      open: options[:open],
      certified: options[:certified],
      pid: options[:pid],
      software: options[:software],
      disciplinary: options[:disciplinary],
      "page[size]" => limit,
      "page[number]" => page,
    }.compact

    url = "https://api.datacite.org/re3data?" + URI.encode_www_form(params)

    response = Maremma.get(url, host: true, skip_encoding: true)

    return [] if response.status != 200

    data =
      Array.wrap(response.body.fetch("data", nil)).map do |message|
        parse_message(
          id: doi_as_url(message["id"]), message: message["attributes"],
        )
      end
    meta = { "total" => response.body.dig("meta", "total") }
    errors = response.body.fetch("errors", nil)

    { data: data, meta: meta, errors: errors }
  end

  def self.parse_message(id: nil, message: nil)
    Hashie::Mash.new(
      id: id,
      type: "DataCatalog",
      re3data_id: message["re3dataId"],
      name: message["repositoryName"],
      url: message["repositoryUrl"],
      contacts: message["repositoryContacts"],
      description: message["description"],
      certificates: message["certificates"],
      types: message["types"],
      repository_languages: message["repositoryLanguages"],
      additional_names: message["additionalNames"],
      subjects: message["subjects"],
      content_types: message["contentTypes"],
      provider_types: message["providerTypes"],
      keywords: message["keywords"],
      data_accesses: message["dataAccesses"],
      data_uploads: message["dataUploads"],
      pid_systems: message["pidSystems"],
      apis: message["apis"],
      software: message["software"],
      updated: message["updated"],
      created: message["created"],
    )
  end

  def self.doi_as_url(doi)
    return nil if doi.blank?

    "https://doi.org/#{doi.downcase}"
  end

  def self.all(pages: 3)
    re3repos = []
    (1..pages).each do |page|
      re3repos += DataCatalog.query("", limit: 1000, offset: page).fetch(:data, [])
    end
    re3repos.uniq!
    re3repos
  end

  def self.warm_re3_cache(re3repos, duration: 5.minutes)
    re3repos.each do | repo |
      doi = repo.id&.gsub("https://doi.org/", "")
      if not doi.blank?
        Rails.cache.write("re3repo/#{doi}", repo, expires_in: duration)
      end
    end
  end

  def self.fetch_and_cache_all(pages: 3, duration: 5.minutes)
    repos = DataCatalog.all(pages: pages)
    DataCatalog.warm_re3_cache(repos, duration: duration)
    repos
  end
end
