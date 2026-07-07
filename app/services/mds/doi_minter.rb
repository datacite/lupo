# frozen_string_literal: true

module Mds
  # DOI identity resolution for MDS metadata registration (path, XML identifier, or mint).
  # Lives outside controllers so Helpable stays off the protocol base class.
  class DoiMinter
    include Bolognese::DoiUtils
    include Bolognese::Utils
    include Helpable

    def resolve_doi_id(str, data:, from:, number: nil)
      doi = validate_doi(str)
      return doi if doi.present?

      if from == "datacite"
        doi = doi_from_xml_identifier(data)
        return doi if doi.present?
      end

      mint_unique_doi(str, number: number)
    end

    private
      def doi_from_xml_identifier(string)
        doc = Nokogiri::XML(string, nil, "UTF-8", &:noblanks)
        doc.remove_namespaces!
        identifier = doc.at_css("identifier")
        identifier = identifier.content if identifier.present?
        validate_doi(identifier)
      end

      def mint_unique_doi(str, number: nil)
        if number.present?
          doi = generate_random_dois(str, number: number).first
          existing = DataciteDoi.where(doi: doi).exists?
          fail IdentifierError, "doi:#{doi} has already been registered" if existing

          return doi
        end

        doi = nil
        loop do
          doi = generate_random_dois(str).first
          break unless DataciteDoi.where(doi: doi).exists?
        end
        doi
      end
  end
end
