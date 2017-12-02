class DataCentersController < ApplicationController
  before_action :set_client, only: [:show]
  before_action :set_include

  def index
    # support nested routes
    if params[:provider_id].present?
      provider = Provider.where('allocator.symbol = ?', params[:provider_id]).first
      collection = provider.present? ? provider.clients : Client.none
    else
      collection = Client
    end

    if params[:id].present?
      collection = collection.where(symbol: params[:id])
    elsif params[:query].present?
      collection = collection.query(params[:query])
    end

    # cache prefixes for faster queries
    if params[:prefix].present?
      prefix = cached_prefix_response(params[:prefix])
      collection = collection.includes(:prefixes).where('prefix.id' => prefix.id)
    end

    collection = collection.where('YEAR(datacentre.created) = ?', params[:year]) if params[:year].present?

    # calculate facet counts after filtering

    providers = collection.joins(:provider).select('allocator.symbol, allocator.name, count(allocator.id) as count').order('count DESC').group('allocator.id')
    # workaround, as selecting allocator.symbol as id doesn't work
    providers = providers.map { |p| { id: p.symbol, title: p.name, count: p.count } }

    if params[:year].present?
      years = client_year_facet
    else
      years = collection.where.not(created: nil).order("YEAR(datacentre.created) DESC").group("YEAR(datacentre.created)").count
      years = years.map { |k,v| { id: k.to_s, title: k.to_s, count: v } }
    end

    page = params[:page] || {}
    page[:number] = page[:number] && page[:number].to_i > 0 ? page[:number].to_i : 1
    page[:size] = page[:size] && (1..1000).include?(page[:size].to_i) ? page[:size].to_i : 25
    total = collection.count

    order = case params[:sort]
            when "-name" then "datacentre.name DESC"
            when "-created" then "datacentre.created DESC"
            when "created" then "datacentre.created"
            else "datacentre.name"
            end

    @clients = collection.order(order).page(page[:number]).per(page[:size])

    meta = { total: total,
             total_pages: @clients.total_pages,
             page: page[:number].to_i,
             providers: providers,
             years: years }

    render jsonapi: @clients, meta: meta, include: @include, each_serializer: DataCenterSerializer
  end

  def show
    render jsonapi: @client, include: @include, serializer: DataCenterSerializer
  end

  protected

  def set_include
    if params[:include].present?
      @include = params[:include].split(",").map { |i| i.downcase.underscore }.join(",")
      @include = [@include]
    else
      @include = nil
    end
  end

  def set_client
    @client = Client.where(symbol: params[:id]).first
    fail ActiveRecord::RecordNotFound unless @client.present?
  end
end
