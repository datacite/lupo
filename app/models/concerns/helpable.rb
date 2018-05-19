module Helpable
  extend ActiveSupport::Concern

  require "bolognese"
  require "cirneco"

  included do
    include Bolognese::Utils
    include Bolognese::DoiUtils
    include Cirneco::Utils

    attr_accessor :username, :password

    def register_url(options={})
      return OpenStruct.new(body: { "errors" => [{ "title" => "Username or password missing" }] }) unless options[:username].present? && options[:password].present?

      payload = "doi=#{doi}\nurl=#{options[:url]}"
      mds_url = Rails.env.production? ? 'https://mds.datacite.org' : 'https://mds.test.datacite.org' 
      url = "#{mds_url}/doi/#{doi}"

      response = Maremma.put(url, content_type: 'text/plain;charset=UTF-8', data: payload, username: options[:username], password: options[:password])

      if response.status == 201
        Rails.logger.info "[Handle] Updated to URL " + options[:url] + " for DOI " + doi + "."
        response
      else
        text = "Error " + response.body.dig("errors", 0, "status").to_s + " " + (response.body.dig("errors", 0, "title") || "unknown") + " for URL " + options[:url] + "."
        title = "Error updating DOI " + doi
        
        Rails.logger.error "[Handle] " + title
        Rails.logger.error text
        User.send_notification_to_slack(text, title: title, level: "danger") unless Rails.env.test?
        response
      end
    end

    def generate_random_doi(str, options={})
      prefix = validate_prefix(str)
      fail IdentifierError, "No valid prefix found" unless prefix.present?

      shoulder = str.split("/", 2)[1].to_s
      encode_doi(prefix, shoulder: shoulder, number: options[:number])
    end

    def epoch_to_utc(epoch)
      Time.at(epoch).to_datetime.utc.iso8601
    end
  end
end
