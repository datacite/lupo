# frozen_string_literal: true

module Mds
  # In-process DOI operations for the classic MDS /doi surface.
  class DoiOperations
    include Bolognese::DoiUtils

    attr_reader :current_user, :current_ability

    def initialize(current_user:)
      @current_user = current_user
      @current_ability = Ability.new(current_user)
    end

    def list
      client =
        Client.where("datacentre.symbol = ?", current_user.uid.upcase).first
      return Result.no_content if client.blank?

      client_prefix = client.prefixes.first
      return Result.no_content if client_prefix.blank?

      unless current_ability.can?(:get_urls, Doi)
        return Result.error(403, "Access is denied")
      end

      dois =
        DataciteDoi.get_dois(
          prefix: client_prefix.uid,
          username: current_user.uid.upcase,
          password: current_user.password,
        )

      if dois.blank? || !dois.is_a?(Array) || dois.empty?
        return Result.no_content
      end

      Result.ok(dois.join("\n"))
    end

    def get_url(doi_string)
      doi_id = validate_doi(doi_string)
      return Result.error(404, "DOI not found") if doi_id.blank?

      doi = DataciteDoi.where(doi: doi_id).first
      return Result.error(404, "DOI not found") if doi.blank?

      unless current_ability.can?(:get_url, doi)
        return Result.error(403, "Access is denied")
      end

      url = resolve_url(doi)
      return Result.no_content if url.blank?

      Result.ok(url)
    end

    def put_url(doi_string, url:)
      return Result.error(400, "Not a valid HTTP(S) or FTP URL") unless valid_landing_url?(url)

      doi_id = validate_doi(doi_string)
      return Result.error(404, "DOI not found") if doi_id.blank?

      doi = DataciteDoi.where(doi: doi_id).first
      exists = doi.present?

      attrs = {
        url: url,
        should_validate: true,
        source: "mds",
        event: "publish",
        client_id: client_symbol,
      }

      if exists
        unless current_ability.can?(:update, doi)
          return Result.error(403, "Access is denied")
        end

        doi.current_user = current_user
        doi.assign_attributes(attrs.except(:client_id))
      else
        doi = DataciteDoi.new(attrs.merge(doi: doi_id))
        doi.current_user = current_user
        unless current_ability.can?(:new, doi)
          return Result.error(403, "Access is denied")
        end
      end

      if doi.save
        Result.created("OK")
      else
        message = doi.errors.full_messages.first || "Unprocessable entity"
        Result.error(422, message)
      end
    rescue ActiveRecord::RecordNotFound
      Result.error(404, "DOI not found")
    end

    def destroy(doi_string)
      doi_id = validate_doi(doi_string)
      return Result.error(404, "DOI not found") if doi_id.blank?

      doi = DataciteDoi.where(doi: doi_id).first
      return Result.error(404, "DOI not found") if doi.blank?

      unless current_ability.can?(:destroy, doi)
        return Result.error(403, "Access is denied")
      end

      unless doi.draft?
        return Result.error(405, "Method not allowed")
      end

      if doi.destroy
        Result.ok("OK")
      else
        message = doi.errors.full_messages.first || "Unprocessable entity"
        Result.error(422, message)
      end
    end

    # Parse classic MDS body: "doi=...\nurl=..." lines.
    def self.extract_url(doi: nil, data: nil)
      hsh =
        data.to_s.split("\n").map do |line|
          arr = line.to_s.split("=", 2)
          arr << "value" if arr.length < 2
          arr
        end.to_h

      fail IdentifierError, "param 'doi' required" unless hsh["doi"].present?

      body_doi = CGI.unescape(hsh["doi"].strip)
      if doi.present? && body_doi.casecmp(doi) != 0
        fail IdentifierError, "doi parameter does not match doi of resource"
      end

      fail IdentifierError, "param 'url' required" unless hsh["url"].present?

      [body_doi, CGI.unescape(hsh["url"].strip)]
    end

    private

    def client_symbol
      (current_user.client_id.presence || current_user.uid).to_s
    end

    def valid_landing_url?(url)
      url.to_s.match?(%r{\A(http|https|ftp)://\S+\z})
    end

    def resolve_url(doi)
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
  end
end
