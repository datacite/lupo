class Repository
  include Searchable
  include Bolognese::Utils

  RE3DATA_DATE = "2017-10-07"

  attr_reader :id, :name, :additional_name, :description, :repository_url, :repository_contact, :subject, :repository_software, :created_at, :updated_at

  def initialize(item, options={})
    @id = item.fetch("id", nil) || item.fetch("re3data.orgIdentifier", nil)
    @name = item.fetch("name", nil) || parse_attributes(item.fetch("repositoryName", nil))
    @additional_name = parse_attributes(item.fetch("additionalName", nil))
    @description = parse_attributes(item.fetch("description", nil))
    @repository_url = item.fetch("repositoryURL", nil)
    @repository_contact = item.fetch("repositoryContact", nil)
    @repository_software = item.dig("software", "softwareName")
    @subject = Array.wrap(parse_attributes(item.fetch("subject", []))).map do |s|
      k, v = s.split(" ", 2)
      { "id" => k.to_i, "name" => v }
    end.sort { |a, b| a.fetch("id") <=> b.fetch("id") }.presence
    @created_at = item.fetch("entryDate", nil).present? ? item.fetch("entryDate") + "T00:00:00Z" : nil
    @updated_at = (item.fetch("lastUpdate", nil) || RE3DATA_DATE) + "T00:00:00Z"
  end

  def self.get_query_url(options={})
    if options[:id].present?
      "#{ENV["RE3DATA_URL"]}/repository/#{options[:id]}"
    else
      params = { query: options.fetch(:query, nil) }.compact
      url + "?" + URI.encode_www_form(params)
    end
  end

  def self.parse_data(result, options={})
    return nil if result.blank? || result['errors']

    if options[:id].present?
      item = result.body.fetch("data", {}).fetch("re3data", {}).fetch("repository", [])
      #return nil unless item.present?
      Rails.logger.info item.inspect
      { data: parse_item(item) }
    else
      items = Array.wrap(result.body.fetch("data", []).fetch("list", {}).fetch("repository", []))

      # sort by name
      items = items.sort { |a, b| a.fetch("name") <=> b.fetch("name") }

      # pagination
      page = options[:page] || {}
      page[:number] = page[:number] && page[:number].to_i > 0 ? page[:number].to_i : 1
      page[:size] = page[:size] && (1..1000).include?(page[:size].to_i) ? page[:size].to_i : 25
      total = items.size

      items = Kaminari.paginate_array(items).page(page[:number]).per(page[:size])

      meta = { total: total,
               total_pages: items.total_pages,
               page: page[:number].to_i }

      { data: parse_items(items), meta: meta }
    end
  end

  def self.url
    "#{ENV["RE3DATA_URL"]}/repositories"
  end
end
