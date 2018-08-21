class DataCentersController < ApplicationController
  before_action :set_client, only: [:show]
  before_action :set_include

  def index
    sort = case params[:sort]
           when "relevance" then { "_score" => { order: 'desc' }}
           when "name" then { "name.raw" => { order: 'asc' }}
           when "-name" then { "name.raw" => { order: 'desc' }}
           when "created" then { created: { order: 'asc' }}
           when "-created" then { created: { order: 'desc' }}
           else { updated: { "order": "asc" }}
           end

    page = params[:page] || {}
    if page[:size].present? 
      page[:size] = [page[:size].to_i, 1000].min
      max_number = 1
    else
      page[:size] = 25
      max_number = 10000/page[:size]
    end
    page[:number] = page[:number].to_i > 0 ? [page[:number].to_i, max_number].min : 1

    if params[:id].present?
      response = Client.find_by_id(params[:id]) 
    elsif params[:ids].present?
      response = Client.find_by_ids(params[:ids], page: page, sort: sort)
    else
      response = Client.query(params[:query], year: params[:year], provider_id: params[:member_id], page: page, sort: sort)
    end

    total = response.results.total
    total_pages = page[:size] > 0 ? (total.to_f / page[:size]).ceil : 0
    years = total > 0 ? facet_by_year(response.response.aggregations.years.buckets) : nil
    providers = total > 0 ? facet_by_provider(response.response.aggregations.providers.buckets) : nil

    @clients = response.results.results

    options = {}
    options[:meta] = {
      total: total,
      "total-pages" => total_pages,
      page: page[:number],
      years: years,
      members: providers
    }.compact

    options[:links] = {
      self: request.original_url,
      next: @clients.blank? ? nil : request.base_url + "/data-centers?" + {
      query: params[:query],
      "member-id" => params[:member_id],
      year: params[:year],
      "page[number]" => page[:number] + 1,
      "page[size]" => page[:size],
      sort: params[:sort] }.compact.to_query
    }.compact
    options[:include] = @include
    options[:is_collection] = true

    render json: DataCenterSerializer.new(@clients, options).serialized_json, status: :ok
  end

  def show
    options = {}
    options[:include] = @include
    options[:is_collection] = false

    render json: DataCenterSerializer.new(@client, options).serialized_json, status: :ok
  end

  protected

  def set_include
    if params[:include].present?
      @include = params[:include].split(",").map { |i| i.downcase.underscore.to_sym }
      @include = @include & [:provider, :repository]
    else
      @include = []
    end
  end

  def set_client
    @client = Client.where(symbol: params[:id]).first
    fail ActiveRecord::RecordNotFound unless @client.present?
  end
end
