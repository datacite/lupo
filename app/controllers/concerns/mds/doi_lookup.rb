# frozen_string_literal: true

module Mds
  module DoiLookup
    extend ActiveSupport::Concern

    included do
      include Bolognese::DoiUtils
    end

    private
      def client_symbol
        (current_user.client_id.presence || current_user.uid).to_s
      end

      def find_datacite_doi!(doi_string, not_found: Mds::DOI_NOT_FOUND)
        doi_id = validate_doi(doi_string)
        fail Mds::Error.new(not_found, status: 404) if doi_id.blank?

        doi = DataciteDoi.where(doi: doi_id).first
        fail Mds::Error.new(not_found, status: 404) if doi.blank?

        doi
      end

      # DOIs for the authenticated repository's first prefix (MDS GET /doi list).
      # Returns nil when there is nothing to list (caller should 204).
      def listed_dois_for_current_user
        client =
          Client.where("datacentre.symbol = ?", current_user.uid.upcase).first
        client_prefix = client&.prefixes&.first
        return if client_prefix.blank?

        dois =
          DataciteDoi.get_dois(
            prefix: client_prefix.uid,
            username: current_user.uid.upcase,
          )
        return if dois.blank? || !dois.is_a?(Array) || dois.empty?

        dois
      end
  end
end
