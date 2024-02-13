# frozen_string_literal: true

class PrefixesController < ApplicationController
  before_action :set_prefix, only: %i[show update destroy]
  before_action :authenticate_user!
  before_action :set_include
  load_and_authorize_resource except: %i[index show totals]
  around_action :skip_bullet, only: %i[index], if: -> { defined?(Bullet) }

  def index
    sort =
      case params[:sort]
      when "relevance"
        { "_score" => { order: "desc" } }
      when "name"
        { "uid" => { order: "asc", unmapped_type: "keyword" } }
      when "-name"
        { "uid" => { order: "desc", unmapped_type: "keyword" } }
      when "created"
        { created_at: { order: "asc" } }
      when "-created"
        { created_at: { order: "desc" } }
      else
        { "uid" => { order: "asc", unmapped_type: "keyword" } }
      end

    page = page_from_params(params)

    response =
      if params[:id].present?
        Prefix.find_by_id(params[:id])
      else
        Prefix.query(
          params[:query],
          year: params[:year],
          state: params[:state],
          provider_id: params[:provider_id],
          client_id: params[:client_id],
          page: page,
          sort: sort,
        )
      end

    begin
      total = response.results.total
      total_pages = page[:size].positive? ? (total.to_f / page[:size]).ceil : 0
      years =
        if total.positive?
          facet_by_year(response.response.aggregations.years.buckets)
        end
      states =
        if total.positive?
          facet_by_key(response.response.aggregations.states.buckets)
        end
      providers =
        if total.positive?
          facet_by_combined_key(
            response.response.aggregations.providers.buckets,
          )
        end
      clients =
        if total.positive?
          facet_by_combined_key(response.response.aggregations.clients.buckets)
        end

      prefixes = response.results

      options = {}
      options[:meta] = {
        total: total,
        "totalPages" => total_pages,
        page: page[:number],
        years: years,
        states: states,
        providers: providers,
        clients: clients,
      }.compact

      options[:links] = {
        self: request.original_url,
        next:
          if prefixes.blank? || page[:number] == total_pages
            nil
          else
            request.base_url + "/prefixes?" +
              {
                query: params[:query],
                prefix: params[:prefix],
                year: params[:year],
                provider_id: params[:provider_id],
                client_id: params[:client_id],
                "page[number]" => page[:number] + 1,
                "page[size]" => page[:size],
                sort: params[:sort],
              }.compact.
              to_query
          end,
      }.compact
      options[:include] = @include
      options[:is_collection] = true

      render(
        json: PrefixSerializer.new(prefixes, options).serializable_hash.to_json,
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
      json: PrefixSerializer.new(@prefix, options).serializable_hash.to_json,
      status: :ok
    )
  end

  def create
    @prefix = Prefix.new(safe_params)
    authorize! :create, @prefix

    if @prefix.save
      options = {}
      options[:include] = @include
      options[:is_collection] = false

      render(
        json: PrefixSerializer.new(@prefix, options).serializable_hash.to_json,
        status: :created,
        location: @prefix
      )
    else
      logger.error @prefix.errors.inspect
      render json: serialize_errors(@prefix.errors),
             status: :unprocessable_entity
    end
  end

  def update
    response.headers["Allow"] = "HEAD, GET, POST, OPTIONS"
    render json: {
      errors: [{ status: "405", title: "Method not allowed" }],
    }.to_json,
           status: :method_not_allowed
  end

  def destroy
    message = "Prefix #{@prefix.uid} deleted."
    if @prefix.destroy
      Rails.logger.warn message
      head :no_content
    else
      Rails.logger.error @prefix.errors.inspect
      render json: serialize_errors(@prefix.errors),
             status: :unprocessable_entity
    end
  end

  def totals
    return [] if params[:client_id].blank?

    page = { size: 0, number: 1 }
    response =
      Doi.query(
        nil,
        client_id: params[:client_id],
        state: "findable,registered",
        page: page,
        totals_agg: "prefix",
      )
    registrant =
      prefixes_totals(response.response.aggregations.prefixes_totals.buckets)

    render json: registrant, status: :ok
  end

  protected
    def set_include
      if params[:include].present?
        @include =
          params[:include].split(",").map { |i| i.downcase.underscore.to_sym }
        @include =
          @include & %i[clients providers client_prefixes provider_prefixes]
      else
        @include = []
      end
    end

  private
    def set_prefix
      @prefix = Prefix.where(uid: params[:id]).first

      # fallback to call handle server, i.e. for prefixes not from DataCite
      unless @prefix.present? || Rails.env.test?
        @prefix = Handle.where(id: params[:id])
      end
      fail ActiveRecord::RecordNotFound if @prefix.blank?
    end

    def safe_params
      ActiveModelSerializers::Deserialization.jsonapi_parse!(
        params,
        only: %i[id created_at], keys: { id: :uid },
      )
    end
end
