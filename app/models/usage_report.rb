# frozen_string_literal: true

class UsageReport
  # include helper module for PORO models
  include Modelable

  def self.find_by_id(id)
    ids = id.split(",")
    base_url =
      if Rails.env.production?
        "https://api.datacite.org/reports"
      else
        "https://api.test.datacite.org/reports"
      end
    return {} unless id.starts_with?(base_url)

    url = id

    response = Maremma.get(url)

    return {} if response.status != 200

    message = response.body.dig("data", "report")
    data = [parse_message(id: id, message: message)]

    errors = response.body.fetch("errors", nil)

    { data: data, errors: errors }
  end

  def self.query(_query, options = {})
    number = (options.dig(:page, :number) || 1).to_i
    size = (options.dig(:page, :size) || 25).to_i

    base_url =
      if Rails.env.production?
        "https://api.datacite.org/reports"
      else
        "https://api.test.datacite.org/reports"
      end
    url = base_url + "?page[size]=#{size}&page[number]=#{number}"

    response = Maremma.get(url)

    return {} if response.status != 200

    data =
      response.body.dig("data", "reports").map do |message|
        parse_message(id: base_url + "/#{message['id']}", message: message)
      end
    meta = { "total" => response.body.dig("data", "meta", "total") }
    errors = response.body.fetch("errors", nil)

    { data: data, meta: meta, errors: errors }
  end

  def self.parse_message(id: nil, message: nil)
    reporting_period = {
      begin_date:
        message.dig("report-header", "reporting-period", "begin-date"),
      end_date: message.dig("report-header", "reporting-period", "end-date"),
    }

    {
      id: id,
      reporting_period: reporting_period,
      client_id: message["client_id"],
      year: message["year"],
      month: message["month"],
      date_modified: message["created"],
    }.compact
  end
end
