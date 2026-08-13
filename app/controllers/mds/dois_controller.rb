# frozen_string_literal: true

module Mds
  class DoisController < Mds::ApplicationController
    include Mds::DoiWriter

    prepend_before_action :authenticate_mds_user!
    before_action :set_doi, only: %i[show destroy]

    def index
      authorize! :get_urls, Doi

      dois = listed_dois_for_current_user
      return head :no_content if dois.blank?

      render_mds(dois.join("\n"))
    end

    def show
      authorize! :get_url, @doi

      url = @doi.resolved_landing_url
      return head :no_content if url.blank?

      render_mds(url)
    end

    def update
      doi_string, url = parse_doi_and_url
      if doi_string.blank? || url.blank?
        fail Mds::Error.new("DOI and URL required", status: 400)
      end

      fail Mds::Error.new("Not a valid HTTP(S) or FTP URL", status: 400) unless valid_landing_url?(url)

      doi_id = validate_doi(doi_string)
      fail Mds::Error.new(Mds::DOI_NOT_FOUND, status: 404) if doi_id.blank?

      upsert_datacite_doi!(
        doi_id,
        url: url,
        should_validate: true,
        source: "mds",
        event: "publish",
        client_id: client_symbol,
      )

      render_mds("OK", status: 201)
    end

    def destroy
      authorize! :destroy, @doi

      unless @doi.draft?
        fail Mds::Error.new("Method not allowed", status: 405)
      end

      unless @doi.destroy
        message = @doi.errors.full_messages.first || "Unprocessable entity"
        fail Mds::Error.new(message, status: 422)
      end

      render_mds("OK")
    end

    private
      def set_doi
        @doi = find_datacite_doi!(params[:id], not_found: Mds::DOI_NOT_FOUND)
      end

      def valid_landing_url?(url)
        url.to_s.match?(%r{\A(http|https|ftp)://\S+\z})
      end

      def parse_doi_and_url
        if (params[:id].present? || params[:doi].present?) && params[:url].present?
          [params[:id].presence || params[:doi], params[:url]]
        elsif request.raw_post.present?
          extract_doi_and_url_from_body(
            request.raw_post,
            path_doi: validate_doi(params[:id]),
          )
        else
          [nil, nil]
        end
      end

      def extract_doi_and_url_from_body(data, path_doi: nil)
        hsh =
          data.to_s.split("\n").map do |line|
            arr = line.to_s.split("=", 2)
            arr << "value" if arr.length < 2
            arr
          end.to_h

        fail IdentifierError, "param 'doi' required" unless hsh["doi"].present?

        body_doi = CGI.unescape(hsh["doi"].strip)
        Mds.assert_path_matches_body!(path_doi, body_doi)

        fail IdentifierError, "param 'url' required" unless hsh["url"].present?

        [body_doi, CGI.unescape(hsh["url"].strip)]
      end
  end
end
