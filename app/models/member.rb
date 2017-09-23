class Member < Base
  attr_reader :id, :title, :description, :member_type, :region, :country, :year, :logo_url, :email, :website, :phone, :created_at, :updated_at

  def initialize(item, options={})
    attributes = item.fetch('attributes', {})
    @id = item.fetch("id", nil).downcase
    @title = attributes.fetch("title", nil)
    @description = Member.sanitize(attributes.fetch("description", nil))
    @member_type = attributes.fetch("member-type", nil)
    @region = attributes.fetch("region", nil)
    @country = attributes.fetch("country", nil)
    @year = attributes.fetch("year", nil)
    @logo_url = attributes.fetch("logo-url", nil)
    @website = attributes.fetch("website", nil)
    @email = attributes.fetch("email", nil)
    @phone = attributes.fetch("phone", nil)
    @created_at = attributes.fetch("created", nil)
    @updated_at = attributes.fetch("updated", nil)
  end

  def self.get_query_url(options={})
    if options[:id].present?
      "#{url}/#{options[:id]}"
    else
      params = { query: options.fetch(:query, nil),
                 member_type: options.fetch("member-type", nil),
                 region: options.fetch(:region, nil),
                 year: options.fetch(:year, nil),
                 "page[size]" => options.dig(:page, :size),
                 "page[number]" => options.dig(:page, :number) }.compact
      url + "?" + URI.encode_www_form(params)
    end
  end

  def self.parse_data(result, options={})
    return nil if result.blank? || result['errors']

    Rails.logger.info result.inspect

    if options[:id].present?
      item = result.body.fetch("data", {})
      return nil unless item.present?

      { data: parse_item(item) }
    else
      items = result.body.fetch("data", [])
      meta = result.body.fetch("meta", {})

      { data: parse_items(items), meta: meta }
    end
  end

  def self.url
    "#{ENV["VOLPINO_URL"]}/members"
  end
end
