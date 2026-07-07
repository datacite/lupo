# frozen_string_literal: true

module Mds
  # In-process media operations for classic MDS /media surface.
  class MediaOperations
    include Bolognese::DoiUtils

    attr_reader :current_user, :current_ability

    def initialize(current_user:)
      @current_user = current_user
      @current_ability = Ability.new(current_user)
    end

    def list(doi_string)
      doi = find_doi(doi_string)
      return doi if doi.is_a?(Result)

      unless current_ability.can?(:read, doi)
        return Result.error(403, "Access is denied")
      end

      media = doi.media.to_a
      return Result.error(404, "No media for the DOI") if media.blank?

      body =
        media.map { |m| "#{m.media_type}=#{m.url}" }.join("\n")
      Result.ok(body)
    end

    def show(doi_string, media_id)
      doi = find_doi(doi_string)
      return doi if doi.is_a?(Result)

      unless current_ability.can?(:read, doi)
        return Result.error(403, "Access is denied")
      end

      media = find_media(doi, media_id)
      return Result.error(404, "No media for the DOI") if media.blank?

      Result.ok("#{media.media_type}=#{media.url}")
    end

    def create(doi_string, data:)
      return Result.error(400, "Media type and URL missing") if data.blank?

      doi = find_doi(doi_string)
      return doi if doi.is_a?(Result)

      unless current_ability.can?(:update, doi)
        return Result.error(403, "Access is denied")
      end

      media_type, url = data.to_s.split("=", 2)
      media = Media.new(doi: doi, media_type: media_type, url: url)

      if media.save
        Result.ok("OK")
      else
        message = media.errors.full_messages.first || "Unprocessable entity"
        Result.error(422, message)
      end
    end

    def destroy(doi_string, media_id)
      doi = find_doi(doi_string)
      return doi if doi.is_a?(Result)

      unless current_ability.can?(:update, doi)
        return Result.error(403, "Access is denied")
      end

      media = find_media(doi, media_id)
      return Result.error(404, "No media for the DOI") if media.blank?

      if media.destroy
        Result.ok("OK")
      else
        message = media.errors.full_messages.first || "Unprocessable entity"
        Result.error(422, message)
      end
    end

    private

    def find_doi(doi_string)
      doi_id = validate_doi(doi_string)
      return Result.error(404, "DOI is unknown to MDS") if doi_id.blank?

      doi = DataciteDoi.where(doi: doi_id).first
      return Result.error(404, "DOI is unknown to MDS") if doi.blank?

      doi
    end

    def find_media(doi, media_id)
      id = Base32::URL.decode(CGI.unescape(media_id.to_s))
      return nil if id.blank?

      doi.media.where(id: id.to_i).first
    end
  end
end
