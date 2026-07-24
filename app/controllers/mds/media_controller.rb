# frozen_string_literal: true

module Mds
  class MediaController < Mds::ApplicationController
    include Mds::DoiLookup

    prepend_before_action :authenticate_mds_user!
    before_action :set_doi
    before_action :set_media, only: %i[show destroy]

    def index
      authorize! :read, @doi

      media = @doi.media.to_a
      fail Mds::Error.new("No media for the DOI", status: 404) if media.blank?

      body = media.map { |m| "#{m.media_type}=#{m.url}" }.join("\n")
      render_mds(body)
    end

    def show
      authorize! :read, @doi

      fail Mds::Error.new("No media for the DOI", status: 404) if @media.blank?

      render_mds("#{@media.media_type}=#{@media.url}")
    end

    def create
      authorize! :update, @doi

      data = request.raw_post
      fail Mds::Error.new("Media type and URL missing", status: 400) if data.blank?

      media_type, url = data.to_s.split("=", 2)
      media = Media.new(doi: @doi, media_type: media_type, url: url)

      unless media.save
        message = media.errors.full_messages.first || "Unprocessable entity"
        fail Mds::Error.new(message, status: 422)
      end

      render_mds("OK")
    end

    def destroy
      authorize! :update, @doi

      fail Mds::Error.new("No media for the DOI", status: 404) if @media.blank?

      unless @media.destroy
        message = @media.errors.full_messages.first || "Unprocessable entity"
        fail Mds::Error.new(message, status: 422)
      end

      render_mds("OK")
    end

    private
      def set_doi
        raw = params[:doi_id]
        fail Mds::Error.new("DOI is unknown to MDS", status: 404) if raw.blank?

        @doi = find_datacite_doi!(raw, not_found: "DOI is unknown to MDS")
      end

      def set_media
        encoded = params[:id]
        fail Mds::Error.new("No media for the DOI", status: 404) if encoded.blank?

        id = Base32::URL.decode(CGI.unescape(encoded.to_s))
        fail Mds::Error.new("No media for the DOI", status: 404) if id.blank?

        @media = @doi.media.where(id: id.to_i).first
      end
  end
end
