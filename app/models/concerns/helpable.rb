module Helpable
  extend ActiveSupport::Concern

  require 'bolognese'
  require 'securerandom'
  require 'base32/url'

  UPPER_LIMIT = 1073741823

  included do
    include Bolognese::Utils
    include Bolognese::DoiUtils

    def register_url
      unless url.present?
        Rails.logger.error "[Handle] Error updating DOI " + doi + ": url missing."
        return OpenStruct.new(body: { "errors" => [{ "title" => "URL missing." }] })
      end

      unless client_id.present?
        Rails.logger.error "[Handle] Error updating DOI " + doi + ": client ID missing."
        return OpenStruct.new(body: { "errors" => [{ "title" => "Client ID missing." }] })
      end

      unless is_registered_or_findable?
        return OpenStruct.new(body: { "errors" => [{ "title" => "DOI is not registered or findable." }] })
      end

      if ENV['HANDLE_URL'].present?
        payload = {
          "index" => 1,
          "type" => "URL",
          "data" => {
            "format" => "string",
            "value" => url
          }
        }.to_json

        url = "#{ENV['HANDLE_URL']}/api/handles/#{doi}?index=1"
        response = Maremma.put(url, content_type: 'application/json;charset=UTF-8', data: payload, username: "300%3A#{ENV['HANDLE_USERNAME']}", password: ENV['HANDLE_PASSWORD'], ssl_self_signed: true, timeout: 10)

        if response.status == 200
          # update minted column after first successful registration in handle system
          if minted.blank?
            timestamp = DateTime.parse(response.body.dig("data", "values", 0, "timestamp")) 
            write_attribute(:minted, timestamp)
            self.save
          end

          response
        else
          Rails.logger.error "[Handle] Error updating URL for DOI " + doi + ": " + response.body.inspect
          response
        end
      else
        payload = "doi=#{doi}\nurl=#{url}"
        url = "#{mds_url}/doi/#{doi}"

        response = Maremma.put(url, content_type: 'text/plain;charset=UTF-8', data: payload, username: client_id, password: ENV['ADMIN_PASSWORD'], timeout: 10)

        if response.status == 201
          Rails.logger.info "[Handle] Updated " + doi + " with " + options[:url] + "."
          response
        else
          Rails.logger.error "[Handle] Error updating DOI " + doi + ": " + response.body.inspect
          response
        end
      end
    end

    def get_url
      if ENV['HANDLE_URL'].present?
        url = "#{ENV['HANDLE_URL']}/api/handles/#{doi}?index=1"
        response = Maremma.get(url, ssl_self_signed: true, timeout: 10)

        if response.status == 200
          response
        else
          Rails.logger.error "[Handle] Error fetching URL for DOI " + doi + ": " + response.body.inspect
          response
        end
      else
        url = "#{mds_url}/doi/#{doi}"

        response = Maremma.get(url, content_type: 'text/plain;charset=UTF-8', username: client_id, password: ENV['ADMIN_PASSWORD'], timeout: 10)

        if response.status == 200
          response
        else
          Rails.logger.error "[Handle] Error fetching URL for DOI " + doi + ": " + response.body.inspect
          response
        end
      end
    end

    def mds_url
      Rails.env.production? ? 'https://mds-legacy.datacite.org' : 'https://mds-legacy.test.datacite.org' 
    end

    def generate_random_doi(str, options={})
      prefix = validate_prefix(str)
      fail IdentifierError, "No valid prefix found" unless prefix.present?

      shoulder = str.split("/", 2)[1].to_s
      encode_doi(prefix, shoulder: shoulder, number: options[:number])
    end

    def encode_doi(prefix, options={})
      prefix = validate_prefix(prefix)
      return nil unless prefix.present?

      number = options[:number].to_s.scan(/\d+/).join("").to_i
      number = SecureRandom.random_number(UPPER_LIMIT) unless number > 0
      shoulder = options[:shoulder].to_s
      shoulder += "-" if shoulder.present?
      length = 8
      split = 4
      prefix.to_s + "/" + shoulder + Base32::URL.encode(number, split: split, length: length, checksum: true)
    end

    def epoch_to_utc(epoch)
      Time.at(epoch).to_datetime.utc.iso8601
    end
  end

  module ClassMethods
    def get_dois(options={})
      if ENV['HANDLE_URL'].present?
        return OpenStruct.new(body: { "errors" => [{ "title" => "Prefix missing" }] }) unless options[:prefix].present?

        url = "#{ENV['HANDLE_URL']}/api/handles?prefix=#{options[:prefix]}"
        response = Maremma.get(url, username: "300%3A#{ENV['HANDLE_USERNAME']}", password: ENV['HANDLE_PASSWORD'], ssl_self_signed: true, timeout: 10)

        if response.status == 200
          response
        else
          text = "Error " + response.body["errors"].inspect
          
          Rails.logger.error "[Handle] " + text
          User.send_notification_to_slack(text, title: "Error #{response.status.to_s}", level: "danger") unless Rails.env.test?
          response
        end
      else
        return OpenStruct.new(body: { "errors" => [{ "title" => "Username missing" }] }) unless options[:username].present?

        password = options[:password] || ENV['ADMIN_PASSWORD']

        mds_url = Rails.env.production? ? 'https://mds-legacy.datacite.org' : 'https://mds-legacy.test.datacite.org' 
        url = "#{mds_url}/doi"

        response = Maremma.get(url, content_type: 'text/plain;charset=UTF-8', username: options[:username], password: password, timeout: 10)

        if [200, 204].include?(response.status)
          response
        elsif response.status == 401
          text = "Error " + response.body["errors"].inspect
          Rails.logger.error "[Handle] " + text

          response
        elsif response.status == 404
          text = "Error " + response.body["errors"].inspect
          Rails.logger.error "[Handle] " + text

          response
        else
          text = "Error " + response.body["errors"].inspect
          Rails.logger.error "[Handle] " + text
          User.send_notification_to_slack(text, title: "Error #{response.status.to_s}", level: "danger") unless Rails.env.test?
          
          response
        end
      end
    end
  end
end
