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

      def find_datacite_doi!(doi_string, not_found: "DOI not found")
        doi_id = validate_doi(doi_string)
        fail Mds::Error.new(not_found, status: 404) if doi_id.blank?

        doi = DataciteDoi.where(doi: doi_id).first
        fail Mds::Error.new(not_found, status: 404) if doi.blank?

        doi
      end
  end
end
