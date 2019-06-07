module Identifiable
  extend ActiveSupport::Concern

  included do
    def normalize_doi(doi)
      doi = Array(/\A(?:(http|https):\/(\/)?(dx\.)?(doi.org|handle.test.datacite.org)\/)?(doi:)?(10\.\d{4,5}\/.+)\z/.match(doi)).last
      # remove non-printing whitespace and downcase
      doi = doi.delete("\u200B").downcase if doi.present?

      "https://doi.org/#{doi}" if doi.present?
    end
  end
end
