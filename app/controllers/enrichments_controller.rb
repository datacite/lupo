# frozen_string_literal: true

class EnrichmentsController < ApplicationController
  PAGE_SIZE = 25

  def index
    doi = params["doi"]&.upcase
    client_id = params["client_id"]
    cursor = params.dig("page", "cursor")

    base_enrichments = base_page_enrichments(doi, client_id)

    enrichments = if cursor.present?
      cursor_updated_at, cursor_id, cursor_page = decode_cursor(cursor)
      base_enrichments.by_cursor(cursor_updated_at, cursor_id)
    else
      base_enrichments
    end

    enrichments = enrichments.order_by_cursor.limit(PAGE_SIZE).to_a

    cursor_page ||= 1

    options = {
      meta: build_meta(base_enrichments, cursor_page),
      links: build_paging_links(enrichments, doi, client_id, cursor_page)
    }

    render(json: EnrichmentSerializer.new(enrichments, options).serializable_hash, status: :ok)
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

    def encode_cursor(hash)
      Base64.urlsafe_encode64(hash.to_json, padding: false)
    rescue
      raise ActionController::InternalServerError, "Failed to encode cursor"
    end

    def decode_cursor(token)
      begin
        decoded_cursor = JSON.parse(Base64.urlsafe_decode64(token))
        cursor_updated_at = Time.iso8601(decoded_cursor.fetch("updated_at"))
        cursor_id = decoded_cursor.fetch("id").to_i
        cursor_page = decoded_cursor.fetch("page", nil).to_i || 0

        Rails.logger.info("cursor_page: #{cursor_page}")

        [cursor_updated_at, cursor_id, cursor_page]
      rescue
        raise ActionController::BadRequest, "Invalid cursor"
      end
    end

    def build_meta(enrichments, cursor_page)
      enrichments_total = enrichments.count

      {
        total: enrichments_total,
        totalPages: (enrichments_total / PAGE_SIZE.to_f).ceil,
        page: cursor_page
      }
    end

    def build_next_link(doi, client_id, next_cursor)
      base_link = request.original_url.split("?").first

      query_string = if doi.present?
        "doi=#{doi}&cursor=#{next_cursor}"
      elsif client_id.present?
        "client-id=#{client_id}&cursor=#{next_cursor}"
      else
        "page[cursor]=#{next_cursor}"
      end

      "#{base_link}?#{query_string}"
    end

    def build_paging_links(enrichments, doi, client_id, cursor_page)
      current_link = request.original_url

      next_cursor = if enrichments.any?
        last = enrichments.last
        encode_cursor(updated_at: last.updated_at.iso8601(6), id: last.id, page: cursor_page + 1)
      end

      next_link = build_next_link(doi, client_id, next_cursor)

      {
        self: current_link,
        next: enrichments.length == PAGE_SIZE ? next_link : nil
      }
    end
end
