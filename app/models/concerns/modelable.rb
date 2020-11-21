module Modelable
  extend ActiveSupport::Concern

  module ClassMethods
    def doi_from_url(url)
      if /\A(?:(http|https):\/\/(dx\.)?(doi.org|handle.test.datacite.org)\/)?(doi:)?(10\.\d{4,5}\/.+)\z/.match?(url)
        uri = Addressable::URI.parse(url)
        uri.path.gsub(/^\//, "").downcase
      end
    end

    def orcid_as_url(orcid)
      return nil if orcid.blank?

      "https://orcid.org/#{orcid}"
    end

    def orcid_from_url(url)
      if /\A(?:(http|https):\/\/(orcid.org)\/)(.+)\z/.match?(url)
        uri = Addressable::URI.parse(url)
        uri.path.gsub(/^\//, "").upcase
      end
    end
  end
end
