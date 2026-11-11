# frozen_string_literal: true

class DoiBatchesController < ApplicationController
  PAGE_SIZE = 25

  prepend_before_action :authenticate_user!

  def show
    batch = find_batch
    authorize! :read, batch

    options = {
      links: {
        self: doi_batch_url(batch.uuid),
        items: items_doi_batch_url(batch.uuid),
      },
    }

    render json: DoiBatchSerializer.new(batch, options).serializable_hash,
           status: :ok
  end

  def items
    batch = find_batch
    authorize! :read, batch

    status = params[:status]
    if status.present? && !status.in?(DoiBatchItem::STATUSES)
      raise ActionController::BadRequest, "Invalid batch item status"
    end

    scope = batch.items.with_status(status)
    cursor = decode_cursor(params.dig(:page, :cursor))
    scope = scope.by_cursor(cursor) if cursor.present?
    batch_items = scope.limit(PAGE_SIZE).to_a

    options = {
      meta: {
        total: batch.items.with_status(status).count,
      },
      links: paging_links(batch, batch_items, status),
    }

    render json: DoiBatchItemSerializer.new(batch_items, options).serializable_hash,
           status: :ok
  end

  private
    def find_batch
      DoiBatch.find_by!(uuid: params[:id])
    end

    def encode_cursor(position)
      Base64.urlsafe_encode64({ position: position }.to_json, padding: false)
    end

    def decode_cursor(token)
      return if token.blank?

      JSON.parse(Base64.urlsafe_decode64(token)).fetch("position").to_i
    rescue JSON::ParserError, ArgumentError, KeyError
      raise ActionController::BadRequest, "Invalid cursor"
    end

    def paging_links(batch, batch_items, status)
      query = {}
      query[:status] = status if status.present?
      self_link = items_doi_batch_url(batch.uuid, query)

      next_link =
        if batch_items.length == PAGE_SIZE
          query[:"page[cursor]"] = encode_cursor(batch_items.last.position)
          items_doi_batch_url(batch.uuid, query)
        end

      { self: self_link, next: next_link }
    end
end
