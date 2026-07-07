# frozen_string_literal: true

module Mds
  # Shared DOI domain helpers for MDS protocol controllers.
  # Thin protocol adapters call these instead of a parallel *Operations stack.
  module DoiSupport
    extend ActiveSupport::Concern

    included do
      include Bolognese::DoiUtils
      include Bolognese::Utils
      include Bolognese::MetadataUtils
      include Helpable
    end

    private

    def client_symbol
      (current_user.client_id.presence || current_user.uid).to_s
    end

    # Load a DataciteDoi by validated DOI string or raise Mds::Error.
    def find_datacite_doi!(doi_string, not_found: "DOI not found")
      doi_id = validate_doi(doi_string)
      fail Mds::Error.new(not_found, status: 404) if doi_id.blank?

      doi = DataciteDoi.where(doi: doi_id).first
      fail Mds::Error.new(not_found, status: 404) if doi.blank?

      doi
    end

    # Single write path for MDS create/update of DataciteDoi records.
    # Used by both PUT /doi (publish URL) and PUT /metadata (register metadata).
    # Callers supply already-shaped attributes (metadata runs ParamsSanitizer first).
    def upsert_datacite_doi!(doi_id, attributes)
      attrs = attributes.to_h.compact.with_indifferent_access
      doi = DataciteDoi.where(doi: doi_id).first

      if doi
        fail Mds::Error.new("Access is denied", status: 403) unless can?(:update, doi)

        doi.current_user = current_user
        doi.assign_attributes(attrs.except(:doi, :client_id))
      else
        doi = DataciteDoi.new(attrs.merge(doi: doi_id))
        doi.current_user = current_user
        fail Mds::Error.new("Access is denied", status: 403) unless can?(:new, doi)
      end

      return doi if doi.save

      message = doi.errors.full_messages.first || "Unprocessable entity"
      fail Mds::Error.new(message, status: 422)
    end

    # Resolve landing URL the same way as DataciteDoisController#get_url domain logic:
    # use stored url for draft/other/special providers; otherwise ask Handle via doi.get_url.
    def resolve_landing_url(doi)
      if !doi.is_registered_or_findable? ||
          %w[europ].include?(doi.provider_id) ||
          doi.type == "OtherDoi"
        return doi.url
      end

      response = doi.get_url
      if response.status == 200
        response.body.dig("data", "values", 0, "data", "value") || doi.url
      else
        doi.url
      end
    end

    def valid_landing_url?(url)
      url.to_s.match?(%r{\A(http|https|ftp)://\S+\z})
    end

    # Classic MDS body: "doi=...\nurl=..." lines (also used when path lacks url param).
    def extract_doi_and_url_from_body(data, path_doi: nil)
      hsh =
        data.to_s.split("\n").map do |line|
          arr = line.to_s.split("=", 2)
          arr << "value" if arr.length < 2
          arr
        end.to_h

      fail IdentifierError, "param 'doi' required" unless hsh["doi"].present?

      body_doi = CGI.unescape(hsh["doi"].strip)
      if path_doi.present? && body_doi.casecmp(path_doi) != 0
        fail IdentifierError, "doi parameter does not match doi of resource"
      end

      fail IdentifierError, "param 'url' required" unless hsh["url"].present?

      [body_doi, CGI.unescape(hsh["url"].strip)]
    end

    # Resolve DOI for metadata registration: path param, XML identifier, or mint.
    def resolve_metadata_doi_id(str, data:, from:, number: nil)
      doi = validate_doi(str)
      return doi if doi.present?

      if from == "datacite"
        doi = doi_from_xml_identifier(data)
        return doi if doi.present?
      end

      mint_unique_doi(str, number: number)
    end

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
      else
        doi = nil
        duplicate = true
        while duplicate
          doi = generate_random_dois(str, number: number).first
          duplicate = !Rails.env.test? && DataciteDoi.where(doi: doi).exists?
        end
      end

      doi
    end
  end
end
