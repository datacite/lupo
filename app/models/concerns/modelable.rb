module Modelable
  extend ActiveSupport::Concern
  
  module ClassMethods
    def doi_from_url(url)
      if /\A(?:(http|https):\/\/(dx\.)?(doi.org|handle.test.datacite.org)\/)?(doi:)?(10\.\d{4,5}\/.+)\z/.match(url)
        uri = Addressable::URI.parse(url)
        uri.path.gsub(/^\//, '').downcase
      end
    end
  end
end
