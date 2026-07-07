# frozen_string_literal: true

module Mds
  # Classic MDS /metadata surface — thin protocol adapter over DataciteDoi domain.
  class MetadataController < Mds::ApplicationController
    include Mds::DoiWriter
    include Bolognese::MetadataUtils

    prepend_before_action :authenticate_mds_user!
    before_action :set_doi, only: %i[destroy]

    def show
      doi = find_datacite_doi!(params[:doi_id], not_found: "DOI is unknown to MDS")
      authorize! :read, doi

      xml = doi.xml
      return head :no_content if xml.blank?

      render xml: xml, status: :ok
    end

    def create
      if request.content_type.to_s.include?("application/x-www-form-urlencoded")
        fail Mds::Error.new(
          "Content type application/x-www-form-urlencoded is not supported",
          status: 415,
        )
      end

      data = request.raw_post
      from = data.blank? ? "datacite" : find_from_format(string: data)
      fail Mds::Error.new("Metadata format not recognized", status: 415) if from.blank?

      doi_id =
        Mds::DoiMinter.new.resolve_doi_id(
          params[:doi_id],
          data: data,
          from: from,
          number: params[:number],
        )
      fail Mds::Error.new("DOI not found", status: 404) if doi_id.blank?

      xml_b64 = data.present? ? Base64.strict_encode64(data) : nil
      attrs =
        ParamsSanitizer.new(
          {
            doi: doi_id,
            xml: xml_b64,
            should_validate: true,
            source: "mds",
            event: "show",
            client_id: client_symbol,
          }.compact,
        ).cleanse

      doi = upsert_datacite_doi!(doi_id, attrs)

      minted = doi.doi.to_s.upcase
      render_mds(
        "OK (#{minted})",
        status: 201,
        headers: { "Location" => "#{Mds.url}/metadata/#{doi.doi}" },
      )
    end

    def destroy
      authorize! :update, @doi

      @doi.current_user = current_user
      @doi.assign_attributes(event: "hide")

      unless @doi.save(validate: false)
        message = @doi.errors.full_messages.first || "Unprocessable entity"
        fail Mds::Error.new(message, status: 422)
      end

      render_mds("OK")
    end

    private

    def set_doi
      @doi = find_datacite_doi!(params[:doi_id], not_found: "DOI is unknown to MDS")
    end
  end
end
