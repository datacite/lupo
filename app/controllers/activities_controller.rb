class ActivitiesController < ApplicationController
  include Countable

  before_action :set_activity, only: [:show]
  before_action :set_include

  def index
    sort = case params[:sort]
           when "relevance" then { "_score" => { order: 'desc' }}
           when "created" then { created: { order: 'asc' }}
           when "-created" then { created: { order: 'desc' }}
           else { created: { order: 'desc' }}
           end

    page = page_from_params(params)

    if params[:id].present?
      response = Activity.find_by_id(params[:id])
    elsif params[:ids].present?
      response = Activity.find_by_id(params[:ids], page: page, sort: sort)
    else
      response = Activity.query(params[:query], uid: params[:doi_id], page: page, sort: sort)
    end

    begin
      total = response.results.total
      total_for_pages = page[:cursor].nil? ? total.to_f : [total.to_f, 10000].min
      total_pages = page[:size] > 0 ? (total_for_pages / page[:size]).ceil : 0

      @activities = response.results

      options = {}
      options[:meta] = {
        total: total,
        "totalPages" => total_pages,
        page: page[:cursor].nil? && page[:number].present? ? page[:number] : nil,
      }.compact

      options[:links] = {
        self: request.original_url,
        next: @activities.size < page[:size] ? nil : request.base_url + "/activities?" + {
          query: params[:query],
          "page[cursor]" => page[:cursor] ? Base64.strict_encode64(Array.wrap(@activities.to_a.last[:sort]).join(',')) : nil,
          "page[number]" => page[:cursor].nil? && page[:number].present? ? page[:number] + 1 : nil,
          "page[size]" => page[:size],
          sort: params[:sort] }.compact.to_query
        }.compact
      options[:include] = @include
      options[:is_collection] = true

      render json: ActivitySerializer.new(@activities, options).serialized_json, status: :ok
    rescue Elasticsearch::Transport::Transport::Errors::BadRequest => exception
      Raven.capture_exception(exception)

      message = JSON.parse(exception.message[6..-1]).to_h.dig("error", "root_cause", 0, "reason")

      render json: { "errors" => { "title" => message }}.to_json, status: :bad_request
    end
  end

  def show
    options = {}
    options[:include] = @include
    options[:is_collection] = false

    render json: ActivitySerializer.new(@activity, options).serialized_json, status: :ok
  end

  protected

  def set_include
    if params[:include].present?
      @include = params[:include].split(",").map { |i| i.downcase.underscore.to_sym }
      @include = @include & [:doi]
    else
      @include = [:doi]
    end
  end

  def set_activity
    response = Activity.find_by_id(params[:id])
    @activity = response.results.first
    fail ActiveRecord::RecordNotFound unless @activity.present?
  end
end
