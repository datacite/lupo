# frozen_string_literal: true

class UsageReport
  # include helper module for PORO models
  include Modelable

  def self.find_by_id(id)
    url = Rails.env.production? ? "https://api.datacite.org/reports/#{id}" : "https://api.test.datacite.org/reports/#{id}"
        
    response = Maremma.get(url)

    return {} if response.status != 200
    
    message = response.body.dig("data", "report")
    data = [parse_message(id: id, message: message)]

    errors = response.body.fetch("errors", nil)

    { data: data, errors: errors }
  end

  def self.query(query, options={})
    number = (options.dig(:page, :number) || 1).to_i
    size = (options.dig(:page, :size) || 25).to_i

    url = Rails.env.production? ? "https://api.datacite.org/reports?page[size]=#{size}&page[number]=#{number}" : "https://api.test.datacite.org/reports?page[size]=#{size}&page[number]=#{number}"
    
    response = Maremma.get(url)

    return {} if response.status != 200

    data = response.body.dig("data", "reports").map do |message|
      parse_message(id: message['id'], message: message)
    end
    meta = { "total" => response.body.dig("data", "meta", "total") }
    errors = response.body.fetch("errors", nil)

    { data: data, meta: meta, errors: errors }
  end

  def self.parse_message(id: nil, message: nil)
    reporting_period = {
      begin_date: message.dig("report-header", "reporting-period", "begin-date"),
      end_date: message.dig("report-header", "reporting-period", "end-date")
    }

    {
      id: id,
      reporting_period: reporting_period,
      date_modified: message["created"] }.compact
  end
end