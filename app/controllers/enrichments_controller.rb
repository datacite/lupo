# frozen_string_literal: true

class EnrichmentsController < ApplicationController
  PAGE_SIZE = 10

  def index
    doi = params["doi"]
    client_id = params["client_id"]
    cursor = params["cursor"]

    if doi.blank? && client_id.blank?
      return render(json: { message: "Missing doi or client-id query string parameter" }, status: :bad_request)
    end

    enrichments = doi.present? ? Enrichment.by_doi(doi) : Enrichment.by_client(client_id)

    if cursor.present?
      decoded_cursor = decode_cursor(cursor)
      cursor_updated_at = Time.iso8601(decoded_cursor.fetch("updated_at"))
      cursor_id = decoded_cursor.fetch("id").to_i

      enrichments = enrichments.by_cursor(cursor_updated_at, cursor_id)
    end

    puts(enrichments.order_by_cursor.limit(PAGE_SIZE).to_sql)
    enrichments = enrichments.order_by_cursor.limit(PAGE_SIZE).to_a

    current_link = request.original_url

    next_cursor = if enrichments.any?
      last = enrichments.last
      encode_cursor(updated_at: last.updated_at.iso8601(6), id: last.id)
    end

    next_link = doi.present? ?
      "#{request.original_url.split("?").first}?doi=#{doi}&cursor=#{next_cursor}" :
      "#{request.original_url.split("?").first}?client-id=#{client_id}&cursor=#{next_cursor}"

    render(json: {
      data: enrichments,
      links: {
        self: current_link,
        next: enrichments.length == PAGE_SIZE ? next_link : nil
      }
    })
  end

  private
    def encode_cursor(hash)
      Base64.urlsafe_encode64(hash.to_json, padding: false)
    rescue
      raise ActionController::BadRequest
    end

    def decode_cursor(token)
      JSON.parse(Base64.urlsafe_decode64(token))
    rescue
      raise ActionController::BadRequest
    end
end
