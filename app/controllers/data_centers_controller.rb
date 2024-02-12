# frozen_string_literal: true

class DataCentersController < ApplicationController
  before_action :set_client, only: %i[show]
  before_action :set_include

  def index
    sort =
      case params[:sort]
      when "relevance"
        { "_score" => { order: "desc" } }
      when "name"
        { "name.raw" => { order: "asc" } }
      when "-name"
        { "name.raw" => { order: "desc" } }
      when "created"
        { created: { order: "asc" } }
      when "-created"
        { created: { order: "desc" } }
      else
        { "name.raw" => { order: "asc" } }
      end

    page = page_from_params(params)

    response =
      if params[:id].present?
        Client.find_by_id(params[:id])
      elsif params[:ids].present?
        Client.find_by_id(params[:ids], page: page, sort: sort)
      else
        Client.query(
          params[:query],
          year: params[:year],
          provider_id: params[:member_id],
          fields: params[:fields],
          page: page,
          sort: sort,
        )
      end

    begin
      total = response.results.total
      total_pages = page[:size] > 0 ? (total.to_f / page[:size]).ceil : 0
      years =
        if total > 0
          facet_by_year(response.response.aggregations.years.buckets)
        end
      providers =
        if total.positive?
          facet_by_combined_key(
            response.response.aggregations.providers.buckets,
          )
        end

      @clients = response.results

      options = {}
      options[:meta] = {
        total: total,
        "total-pages" => total_pages,
        page: page[:number],
        years: years,
        members: providers,
      }.compact

      options[:links] = {
        self: request.original_url,
        next:
          if @clients.blank? || page[:number] == total_pages
            nil
          else
            request.base_url + "/data-centers?" +
              {
                query: params[:query],
                "member-id" => params[:member_id],
                year: params[:year],
                fields: params[:fields],
                "page[number]" => page[:number] + 1,
                "page[size]" => page[:size],
                sort: params[:sort],
              }.compact.
              to_query
          end,
      }.compact
      options[:include] = @include
      options[:is_collection] = true
      options[:links] = nil

      render(
        json: DataCenterSerializer.new(@clients, options).serialized_json,
        status: :ok
      )
    rescue Elasticsearch::Transport::Transport::Errors::BadRequest => e
      Raven.capture_exception(e)

      message =
        JSON.parse(e.message[6..-1]).to_h.dig(
          "error",
          "root_cause",
          0,
          "reason",
        )

      render json: { "errors" => { "title" => message } }.to_json,
             status: :bad_request
    end
  end

  def show
    options = {}
    options[:include] = @include
    options[:is_collection] = false

    render(
      json: DataCenterSerializer.new(@client, options).serialized_json,
      status: :ok
    )
  end

  protected
    def set_include
      if params[:include].present?
        include_keys = { "member" => :provider }
        @include =
          params[:include].split(",").reduce([]) do |sum, i|
            k = include_keys[i.downcase.underscore]
            sum << k if k.present?
            sum
          end
      else
        @include = []
      end
    end

    def set_client
      @client = Client.where(symbol: params[:id]).where(deleted_at: nil).first
      fail ActiveRecord::RecordNotFound if @client.blank?
    end
end
