module Helpable
  extend ActiveSupport::Concern

  require "bolognese"
  require "cirneco"

  included do
    include Bolognese::Utils
    include Bolognese::DoiUtils
    include Cirneco::Utils

    def register_url(options={})
      unless options[:username].present? && options[:password].present?
        Rails.logger.error "[Handle] Error updating DOI " + doi + ": Username or password missing."
        return OpenStruct.new(body: { "errors" => [{ "title" => "Username or password missing." }] })
      end

      unless options[:role_id] == "client_admin"
        Rails.logger.error "[Handle] Error updating DOI " + doi + ": User does not have permission to register handle."
        return OpenStruct.new(body: { "errors" => [{ "title" => "User does not have permission to register handle." }] })
      end


      payload = "doi=#{doi}\nurl=#{options[:url]}"
      mds_url = Rails.env.production? ? 'https://mds.datacite.org' : 'https://mds.test.datacite.org' 
      url = "#{mds_url}/doi/#{doi}"

      response = Maremma.put(url, content_type: 'text/plain;charset=UTF-8', data: payload, username: options[:username], password: options[:password])

      if response.status == 201
        Rails.logger.info "[Handle] Updated " + doi + " with " + options[:url] + "."
        response
      else
        Rails.logger.error "[Handle] Error updating DOI " + doi + ": " + (response.body.dig("errors", 0, "title") || "unknown")
        response
      end
    end

    def get_url(options={})
      return OpenStruct.new(body: { "errors" => [{ "title" => "Username or password missing" }] }) unless options[:username].present? && options[:password].present?

      mds_url = Rails.env.production? ? 'https://mds.datacite.org' : 'https://mds.test.datacite.org' 
      url = "#{mds_url}/doi/#{doi}"

      response = Maremma.get(url, content_type: 'text/plain;charset=UTF-8', username: options[:username], password: options[:password])

      if response.status == 200
        response
      else
        text = "Error " + response.body.dig("errors", 0, "status").to_s + " " + (response.body.dig("errors", 0, "title") || "unknown") + " for URL " + options[:url] + "."
        
        Rails.logger.error "[Handle] " + text
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
