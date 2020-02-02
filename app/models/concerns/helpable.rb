module Helpable
  extend ActiveSupport::Concern

  require 'bolognese'
  require 'csv'
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

      payload = [
        {
          "index" => 100,
          "type" => "HS_ADMIN",
          "data" => {
            "format" => "admin",
            "value" => {
              "handle" => ENV['HANDLE_USERNAME'],
              "index" => 300,
              "permissions" => "111111111111"
            }
          }
        },
        {
          "index" => 1,
          "type" => "URL",
          "data" => {
            "format" => "string",
            "value" => url,
          }
        }
      ].to_json

      handle_url = "#{ENV['HANDLE_URL']}/api/handles/#{doi}"
      response = Maremma.put(handle_url, content_type: 'application/json;charset=UTF-8', data: payload, username: "300%3A#{ENV['HANDLE_USERNAME']}", password: ENV['HANDLE_PASSWORD'], ssl_self_signed: true, timeout: 10)

      if [200, 201].include?(response.status)
        # update minted column after first successful registration in handle system
        self.update_attributes(minted: Time.zone.now, updated: Time.zone.now) if minted.blank?
        Rails.logger.info "[Handle] URL for DOI " + doi + " updated to " + url + "." unless Rails.env.test?

        self.__elasticsearch__.index_document
      else
        Rails.logger.error "[Handle] Error updating URL for DOI " + doi + ": " + response.body.inspect unless Rails.env.test?
      end

      response
    end

    def merge_array_hashes(first_array, second_array)
      return first_array if second_array.blank?
      return second_array if first_array.blank?

      total = first_array | second_array
      total.group_by { |hash| hash[:id] }.map do |key, value|
        metrics = value.reduce(&:merge)
        { id: key }.merge(metrics)
      end
    end

    def get_url
      url = "#{ENV['HANDLE_URL']}/api/handles/#{doi}?index=1"
      response = Maremma.get(url, ssl_self_signed: true, timeout: 10)

      if response.status != 200
        Rails.logger.error "[Handle] Error fetching URL for DOI " + doi + ": " + response.body.inspect unless Rails.env.test?
      end

      response
    end

    def generate_random_provider_symbol
      "4:X".gen
    end

    def generate_random_repository_symbol
      "6:X".gen
    end

    def generate_random_dois(str, options={})
      prefix = validate_prefix(str)
      fail IdentifierError, "No valid prefix found" unless prefix.present?

      shoulder = str.split("/", 2)[1].to_s
      encode_doi(prefix, shoulder: shoulder, number: options[:number], size: options[:size])
    end

    def encode_doi(prefix, options={})
      return nil unless prefix.present?

      number = options[:number].to_s.scan(/\d+/).join("").to_i
      shoulder = options[:shoulder].to_s
      shoulder += "-" if shoulder.present?
      length = 8
      split = 4
      size = (options[:size] || 1).to_i

      Array.new(size).map do |a|
        n = number > 0 ? number : SecureRandom.random_number(UPPER_LIMIT)
        prefix.to_s + "/" + shoulder + Base32::URL.encode(n, split: split, length: length, checksum: true)
      end.uniq
    end

    def epoch_to_utc(epoch)
      Time.at(epoch).to_datetime.utc.iso8601
    end

    def https_to_http(url)
      uri = Addressable::URI.parse(url)
      uri.scheme = "http"
      uri.to_s
    end
  end

  module ClassMethods
    def get_dois(options={})
      return OpenStruct.new(body: { "errors" => [{ "title" => "Prefix missing" }] }) unless options[:prefix].present?

      count_url = ENV['HANDLE_URL'] + "/api/handles?prefix=#{options[:prefix]}&pageSize=0"
      response = Maremma.get(count_url, username: "300%3A#{ENV['HANDLE_USERNAME']}", password: ENV['HANDLE_PASSWORD'], ssl_self_signed: true, timeout: 60)

      total = response.body.dig("data", "totalCount").to_i
      dois = []

      if total > 0
        # walk through paginated results
        total_pages = (total.to_f / 1000).ceil
        
        (0...total_pages).each do |page|
          url = ENV['HANDLE_URL'] + "/api/handles?prefix=#{options[:prefix]}&page=#{page}&pageSize=1000"
          response = Maremma.get(url, username: "300%3A#{ENV['HANDLE_USERNAME']}", password: ENV['HANDLE_PASSWORD'], ssl_self_signed: true, timeout: 60)
          if response.status == 200
            dois += (response.body.dig("data", "handles") || [])
          else
            text = "Error " + response.body["errors"].inspect

            Rails.logger.error "[Handle] " + text
            User.send_notification_to_slack(text, title: "Error #{response.status.to_s}", level: "danger") unless Rails.env.test?
          end
        end
      end

      Rails.logger.info "#{total} DOIs found."

      dois
    end

    def get_doi(options={})
      return OpenStruct.new(body: { "errors" => [{ "title" => "DOI missing" }] }) unless options[:doi].present?

      url = Rails.env.production? ? "https://doi.org" : "https://handle.test.datacite.org"
      url += "/api/handles/#{options[:doi]}"
      response = Maremma.get(url, username: "300%3A#{ENV['HANDLE_USERNAME']}", password: ENV['HANDLE_PASSWORD'], ssl_self_signed: true, timeout: 10)

      if response.status != 200
        text = "Error " + response.body["errors"].inspect

        Rails.logger.error "[Handle] " + text
        User.send_notification_to_slack(text, title: "Error #{response.status.to_s}", level: "danger") unless Rails.env.test?
      end

      response
    end

    def delete_doi(options={})
      return OpenStruct.new(body: { "errors" => [{ "title" => "DOI missing" }] }) unless options[:doi].present?
      return OpenStruct.new(body: { "errors" => [{ "title" => "Only DOIs with prefix 10.5072 can be deleted" }] }) unless options[:doi].start_with?("10.5072")

      url = "#{ENV['HANDLE_URL']}/api/handles/#{options[:doi]}"
      response = Maremma.delete(url, username: "300%3A#{ENV['HANDLE_USERNAME']}", password: ENV['HANDLE_PASSWORD'], ssl_self_signed: true, timeout: 10)

      if response.status == 200
        response
      else
        text = "Error " + response.body["errors"].inspect

        Rails.logger.error "[Handle] " + text
        User.send_notification_to_slack(text, title: "Error #{response.status.to_s}", level: "danger") unless Rails.env.test?
        response
      end
    end

    def parse_attributes(element, options={})
      content = options[:content] || "__content__"

      if element.is_a?(String) && options[:content].nil?
        CGI.unescapeHTML(element)
      elsif element.is_a?(Hash)
        element.fetch( CGI.unescapeHTML(content), nil)
      elsif element.is_a?(Array)
        a = element.map { |e| e.is_a?(Hash) ? e.fetch( CGI.unescapeHTML(content), nil) : e }.uniq
        a = options[:first] ? a.first : a.unwrap
      else
        nil
      end
    end
  end
end
