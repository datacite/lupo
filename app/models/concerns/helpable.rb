module Helpable
  extend ActiveSupport::Concern

  require 'bolognese'
  require 'securerandom'
  require 'base32/url'

  UPPER_LIMIT = 1073741823

  included do
    include Bolognese::Utils
    include Bolognese::DoiUtils

    def register_url(options={})
      unless client_id.present?
        Rails.logger.error "[Handle] Error updating DOI " + doi + ": client ID missing."
        return OpenStruct.new(body: { "errors" => [{ "title" => "Client ID missing." }] })
      end

      password = options[:password].presence || ENV['ADMIN_PASSWORD']

      unless is_registered_or_findable?
        return OpenStruct.new(body: { "errors" => [{ "title" => "DOI is not registered or findable." }] })
      end

      payload = "doi=#{doi}\nurl=#{options[:url]}"
      url = "#{mds_url}/doi/#{doi}"

      response = Maremma.put(url, content_type: 'text/plain;charset=UTF-8', data: payload, username: client_id, password: password, timeout: 10)

      if response.status == 201
        Rails.logger.info "[Handle] Updated " + doi + " with " + options[:url] + "."
        response
      elsif [408, 502, 503, 504].include?(response.status)
        Rails.logger.error "[Handle] Error updating DOI " + doi + ": " + response.body.inspect
        #fail Faraday::TimeoutError
      elsif response.status == 500 && response.body.to_s.start_with?("Another user has changed this record")
        Rails.logger.error "[Handle] Error updating DOI " + doi + ": " + response.body.inspect
        #fail ActiveRecord::Deadlocked
      else
        Rails.logger.error "[Handle] Error updating DOI " + doi + ": " + response.body.inspect
        response
      end
    end

    def get_url(options={})
      password = options[:password] || ENV['ADMIN_PASSWORD']

      if ENV['HANDLE_URL'].present?
        url = "#{ENV['HANDLE_URL']}/api/handles/#{doi}?index=1"
        response = Maremma.get(url, ssl_self_signed: true, timeout: 10)

        if response.status == 200
          response
        elsif response.status == 401
          raise CanCan::AccessDenied
        elsif response.status == 404
          raise ActiveRecord::RecordNotFound, "DOI not found"
        else
          Rails.logger.error "[Handle] Error fetching URL for DOI " + doi + ": " + response.body.inspect
          response
        end
      else
        url = "#{mds_url}/doi/#{doi}"

        response = Maremma.get(url, content_type: 'text/plain;charset=UTF-8', username: client_id, password: password, timeout: 10)

        if response.status == 200
          response
        elsif response.status == 401
          raise CanCan::AccessDenied
        elsif response.status == 404
          raise ActiveRecord::RecordNotFound, "DOI not found"
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
      return OpenStruct.new(body: { "errors" => [{ "title" => "Username missing" }] }) unless options[:username].present?

      password = options[:password] || ENV['ADMIN_PASSWORD']

      mds_url = Rails.env.production? ? 'https://mds-legacy.datacite.org' : 'https://mds-legacy.test.datacite.org' 
      url = "#{mds_url}/doi"

      response = Maremma.get(url, content_type: 'text/plain;charset=UTF-8', username: options[:username], password: password, timeout: 10)

      if [200, 204].include?(response.status)
        response
      elsif response.status == 401
        raise CanCan::AccessDenied
      elsif response.status == 404
        raise ActiveRecord::RecordNotFound
      else
        text = "Error " + response.body["errors"].inspect
        
        Rails.logger.error "[Handle] " + text
        User.send_notification_to_slack(text, title: "Error #{response.status.to_s}", level: "danger") unless Rails.env.test?
        response
      end
    end
  end
end
