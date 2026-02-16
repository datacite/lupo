# frozen_string_literal: true

class EnrichmentsController < ApplicationController
  PAGE_SIZE = 25

  def index
    doi = params["doi"]&.upcase
    client_id = params["client_id"]&.upcase
    cursor = params["cursor"]

    enrichments = base_page_enrichments(doi, client_id)
    enrichments = cursor.present? ? filter_enrichments_with_cursor(enrichments, cursor) : enrichments
    enrichments = enrichments.order_by_cursor.limit(PAGE_SIZE).to_a

    current_link = request.original_url

    next_cursor = if enrichments.any?
      last = enrichments.last
      encode_cursor(updated_at: last.updated_at.iso8601(6), id: last.id)
    end

    next_link = build_next_link(doi, client_id, next_cursor)

    render(json: {
      data: enrichments,
      links: {
        self: current_link,
        next: enrichments.length == PAGE_SIZE ? next_link : nil
      }
    })
  end

  private
    def base_page_enrichments(doi, client_id)
      if doi.present?
        Enrichment.by_doi(doi)
      elsif client_id.present?
        Enrichment.by_client(client_id)
      else
        Enrichment.all
      end
    end

    def filter_enrichments_with_cursor(enrichments, cursor)
      begin
        decoded_cursor = decode_cursor(cursor)
        cursor_updated_at = Time.iso8601(decoded_cursor.fetch("updated_at"))
        cursor_id = decoded_cursor.fetch("id").to_i
      rescue
        raise ActionController::BadRequest, "Invalid cursor"
      end

      enrichments.by_cursor(cursor_updated_at, cursor_id)
    end

    def encode_cursor(hash)
      Base64.urlsafe_encode64(hash.to_json, padding: false)
    rescue
      raise ActionController::BadRequest
    end

    def decode_cursor(token)
      JSON.parse(Base64.urlsafe_decode64(token))
    end

    def build_next_link(doi, client_id, next_cursor)
      base_link = request.original_url.split("?").first

      query_string = if doi.present?
        "doi=#{doi}&cursor=#{next_cursor}"
      elsif client_id.present?
        "client-id=#{client_id}&cursor=#{next_cursor}"
      else
        "cursor=#{next_cursor}"
      end

      "#{base_link}?#{query_string}"
    end
end
