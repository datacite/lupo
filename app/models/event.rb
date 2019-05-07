class Event
  # include helper module for PORO models
  include Modelable

  def self.find_by_id(id)
    return { errors: [{ "title" => "No id provided"} ] } unless id.present?

    url = "https://api.datacite.org/events/#{id}"
    response = Maremma.get(url, accept: "application/vnd.api+json; version=2")

    if response.status == 200
      message = response.body.dig("data", "attributes")
      data = [parse_message(id: id, message: message)]
    else
      data = []
    end
    
    { data: data,
      meta: response.body.fetch("meta", {}),
      errors: response.body.fetch("errors", []) }
  end

  def self.query(query, options={})
    size = options[:limit] || 100
    doi = options[:doi].present? ? doi_from_url(options[:doi]) : nil

    url = "https://api.datacite.org/events?page[size]=#{size}"
    url += "&relation-type-id=#{options[:relation_type_id]}" if options[:relation_type_id].present?
    url += "&source-id=#{options[:source_id]}" if options[:source_id].present?
    url += "&doi=#{doi}" if doi.present?
    
    response = Maremma.get(url, accept: "application/vnd.api+json; version=2")

    if response.status == 200
      items = response.body.fetch("data", [])
      data = items.map { |message| parse_message(id: message['id'], message: message['attributes']) }
    else
      data = []
    end

    { data: data,
      meta: response.body.fetch("meta", {}),
      errors: response.body.fetch("errors", []) }
  end

  def self.parse_message(id: nil, message: nil)
    {
      id: id,
      subj_id: message["subjId"],
      obj_id: message["objId"],
      source_id: message["sourceId"],
      relation_type_id: message["relationTypeId"],
      total: message["total"] }.compact
  end
end
