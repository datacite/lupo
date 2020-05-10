class DataCatalog
  # include helper module for PORO models
  include Modelable

  def self.find_by_id(id)
    doi = doi_from_url(id)
    return {} unless doi.present?

    url = "https://api.datacite.org/re3data/#{doi}"
    response = Maremma.get(url, host: true)

    return {} if response.status != 200 || response.body.dig("data", "id") != doi.upcase
    
    message = response.body.dig("data", "attributes")
    data = [parse_message(id: id, message: message)]

    errors = response.body.fetch("errors", nil)

    { data: data, errors: errors }
  end

  def self.query(query, options={})
    limit ||= 25
    page ||= 1

    params = {
      query: query,
      subject: options[:subject],
      open: options[:open], 
      certified: options[:certified],
      pid: options[:pid],
      software: options[:software],
      disciplinary: options[:disciplinary],
      "page[size]" => limit,
      "page[number]" => page }.compact

    url = "https://api.datacite.org/re3data?" + URI.encode_www_form(params)

    response = Maremma.get(url, host: true)

    return [] if response.status != 200
    
    data = Array.wrap(response.body.fetch("data", nil)).map do |message|
      parse_message(id: doi_as_url(message["id"]), message: message["attributes"])
    end
    meta = { "total" => response.body.dig("meta", "total") }
    errors = response.body.fetch("errors", nil)

    { 
      data: data, 
      meta: meta, 
      errors: errors }
  end

  def self.parse_message(id: nil, message: nil)
    Hashie::Mash.new({
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
      software: message["software"] })
  end

  def self.doi_as_url(doi)
    return nil unless doi.present?

    "https://doi.org/#{doi.downcase}"
  end
end
