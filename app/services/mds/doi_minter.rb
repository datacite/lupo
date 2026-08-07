# frozen_string_literal: true

module Mds
  # DOI identity resolution for MDS metadata registration (path, XML identifier, or mint).
  # Uses DoiMinting only — not the full Helpable model concern (handle, landing URL, etc.).
  class DoiMinter
    include Bolognese::DoiUtils
    include DoiMinting

    def resolve_doi_id(str, data:, from:, number: nil)
      path_doi = validate_doi(str)
      body_doi = from == "datacite" ? doi_from_xml_identifier(data) : nil

      if path_doi.present?
        ensure_path_matches_body!(path_doi, body_doi)
        return path_doi
      end

      return body_doi if body_doi.present?

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

      # Same consistency rule as MDS PUT /doi path vs body doi parameter.
      def ensure_path_matches_body!(path_doi, body_doi)
        return if body_doi.blank?
        return if body_doi.casecmp(path_doi).zero?

        fail IdentifierError, "doi parameter does not match doi of resource"
      end

      def mint_unique_doi(str, number: nil)
        # Fail closed before generate_random_dois so blank/malformed mint
        # input returns a deterministic MDS client error (IdentifierError → 400).
        prefix = validate_prefix(str)
        fail IdentifierError, "No valid prefix found" if prefix.blank?

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
