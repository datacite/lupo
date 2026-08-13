# frozen_string_literal: true

module Mds
  # DOI identity resolution for MDS metadata registration (path, XML identifier, or mint).
  # Uses DoiMinting only — not the full Helpable model concern (handle, landing URL, etc.).
  class DoiMinter
    include Bolognese::DoiUtils
    include DoiMinting

    def resolve_doi_id(str, data:, from:, number: nil)
      path_doi = validate_doi(str)
      body_doi = doi_from_metadata_body(data, from)

      if path_doi.present?
        Mds.assert_path_matches_body!(path_doi, body_doi)
        return path_doi
      end

      return body_doi if body_doi.present?

      mint_unique_doi(str, number: number)
    end

    private
      # Extract a DOI identifier from the metadata body for any recognized format.
      # DataCite XML uses a direct parse; other formats go through Bolognese.
      def doi_from_metadata_body(data, from)
        return if data.blank? || from.blank?

        if from == "datacite"
          return doi_from_xml_identifier(data)
        end

        doi_from_bolognese(data, from)
      end

      def doi_from_xml_identifier(string)
        doc = Nokogiri::XML(string, nil, "UTF-8", &:noblanks)
        doc.remove_namespaces!
        identifier = doc.at_css("identifier")
        identifier = identifier.content if identifier.present?
        validate_doi(identifier)
      end

      def doi_from_bolognese(string, from)
        meta = Bolognese::Metadata.new(input: string, from: from)
        validate_doi(meta.doi.presence || meta.id)
      rescue StandardError
        nil
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
