class Event
  def self.find_by_id(id)
    return [] unless id.present?

    url = "https://api.datacite.org/events/#{id}"
    response = Maremma.get(url, accept: "application/vnd.api+json; version=2")

    return [] if response.status != 200
    
    message = response.body.dig("data", "attributes")
    [parse_message(id: id, message: message)]
  end

  def self.query(query, options={})
    size = options[:limit] || 100

    url = "https://api.datacite.org/events?page[size]=#{size}"
    url += "&relation-type-id=#{options[:relation_type_id]}" if options[:relation_type_id].present?
    url += "&source-id=#{options[:source_id]}" if options[:source_id].present?
    
    response = Maremma.get(url, accept: "application/vnd.api+json; version=2")

    return [] if response.status != 200
    
    items = response.body.fetch("data", [])
    items.map do |message|
      parse_message(id: message['id'], message: message['attributes'])
    end
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
