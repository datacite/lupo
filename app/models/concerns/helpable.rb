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
      unless options[:username].present? && options[:password].present?
        Rails.logger.error "[Handle] Error updating DOI " + doi + ": Username or password missing."
        return OpenStruct.new(body: { "errors" => [{ "title" => "Username or password missing." }] })
      end

      unless options[:role_id] == "client_admin"
        Rails.logger.error "[Handle] Error updating DOI " + doi + ": User does not have permission to register handle."
        return OpenStruct.new(body: { "errors" => [{ "title" => "User does not have permission to register handle." }] })
      end

      unless is_registered_or_findable?
        return OpenStruct.new(body: { "errors" => [{ "title" => "DOI is not registered or findable." }] })
      end

      payload = "doi=#{doi}\nurl=#{options[:url]}"
      url = "#{mds_url}/doi/#{doi}"

      response = Maremma.put(url, content_type: 'text/plain;charset=UTF-8', data: payload, username: options[:username], password: options[:password], timeout: 10)

      if response.status == 201
        Rails.logger.info "[Handle] Updated " + doi + " with " + options[:url] + "."
        response
      else
        Rails.logger.error "[Handle] Error updating DOI " + doi + ": " + response.body.inspect
        response
      end
    end

    def get_url(options={})
      return OpenStruct.new(body: { "errors" => [{ "title" => "Username or password missing" }] }) unless options[:username].present? && options[:password].present?

      url = "#{mds_url}/doi/#{doi}"

      response = Maremma.get(url, content_type: 'text/plain;charset=UTF-8', username: options[:username], password: options[:password], timeout: 10)

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
      return OpenStruct.new(body: { "errors" => [{ "title" => "Username or password missing" }] }) unless options[:username].present? && options[:password].present?

      mds_url = Rails.env.production? ? 'https://mds-legacy.datacite.org' : 'https://mds-legacy.test.datacite.org' 
      url = "#{mds_url}/doi"

      response = Maremma.get(url, content_type: 'text/plain;charset=UTF-8', username: options[:username], password: options[:password], timeout: 10)

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
