# frozen_string_literal: true

module Mds
  module DoiWriter
    extend ActiveSupport::Concern

    included do
      include Mds::DoiLookup
    end

    private
      def upsert_datacite_doi!(doi_id, attributes)
        attrs = attributes.to_h.compact.with_indifferent_access
        doi = DataciteDoi.where(doi: doi_id).first

        if doi
          authorize! :update, doi
          doi.current_user = current_user
          doi.assign_attributes(attrs.except(:doi, :client_id))
        else
          doi = DataciteDoi.new(attrs.merge(doi: doi_id))
          doi.current_user = current_user
          authorize! :new, doi
        end

        return doi if doi.save

        message = doi.errors.full_messages.first || "Unprocessable entity"
        fail Mds::Error.new(message, status: 422)
      end
  end
end
