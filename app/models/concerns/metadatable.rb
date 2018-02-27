module Metadatable
  extend ActiveSupport::Concern

  included do
    def get_doi_ra(doi, options = {})
      return {} if doi.blank?

      options[:timeout] ||= 120
      doi = CGI.unescape(clean_doi(doi))
      prefix_string = Array(/^(10\.\d{4,5})\/.+/.match(doi)).last
      return {} if prefix_string.blank?

      # return registration agency cached in Redis if it exists and not test
      unless options[:test]
        ra = redis.get prefix_string
        return ra if ra.present?
      end

      url = "http://doi.crossref.org/doiRA/#{doi}"
      response = Maremma.get(url, options.merge(host: true))

      response["errors"] = [{ "status" => 400, "title" => response["data"] }] if response["data"].is_a?(String)
      return response["errors"] if response["errors"].present?

      ra = response.fetch("data", [{}]).first.fetch("RA", nil)
      if ra.present?
        ra = ra.delete(' ').downcase

        # store prefix/registration agency pair in Redis unless test
        redis.set prefix_string, ra unless options[:test]
        ra
      else
        error = response.fetch("data", [{}]).first.fetch("status", "An error occured")
        { "errors" => [{ "title" => error, "status" => 400 }] }
      end
    end

    # remove non-printing whitespace
    def clean_doi(doi)
      doi.gsub(/\u200B/, '')
    end
  end
end
