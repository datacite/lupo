class Researcher
  def self.find_by_id(id)
    orcid = orcid_from_url(id)
    return {} unless orcid.present?

    url = "https://pub.orcid.org/v2.1/#{orcid}/person"
    response = Maremma.get(url, accept: "application/vnd.orcid+json")

    return {} if response.status != 200

    message = response.body.fetch("data", {})
    data = [parse_message(id: id, message: message)]

    errors = response.body.fetch("errors", nil)

    { data: data, errors: errors }
  end

  def self.parse_message(id: nil, message: nil)
    {
      id: id,
      name: message.dig("name", "credit-name", "value"),
      "givenName" => message.dig("name", "given-names", "value"),
      "familyName" => message.dig("name", "family-name", "value") }.compact
  end

  def self.orcid_from_url(url)
    Array(/\A(http|https):\/\/orcid\.org\/(.+)/.match(url)).last
  end
end
