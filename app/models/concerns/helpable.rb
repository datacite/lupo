module Helpable
  extend ActiveSupport::Concern

  require "bolognese"
  require "cirneco"

  included do
    include Bolognese::DoiUtils
    include Cirneco::Utils
    include Cirneco::Api

    attr_accessor :username, :password

    def register_url(options={})
      return OpenStruct.new(body: { "errors" => [{ "title" => "Username or password missing" }] }) unless options[:username].present? && options[:password].present?

      response = put_doi(doi, url: options[:url],
                              username: options[:username],
                              password: options[:password],
                              sandbox: !Rails.env.production?)

      if response.status == 201
        Rails.logger.info "[Handle] Updated to URL " + url + " for DOI " + doi + "."
        response
      else
        Rails.logger.info "[Handle] Error updating URL " + url + " for DOI " + doi + "."
        Rails.logger.info response.body["errors"].inspect
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
