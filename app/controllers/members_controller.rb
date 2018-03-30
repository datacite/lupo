class MembersController < ApplicationController
  before_action :set_provider, only: [:show]
  before_action :set_include

  def index
    collection = Provider

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

    if params[:client_id].present?
      client = cached_client_response(params[:client_id].upcase)
      collection = collection.includes(:clients).where('datacentre.id' => client.id)
    end

    collection = collection.where(region: params[:region]) if params[:region].present?
    collection = collection.where(institution_type: params[:institution_type]) if params[:institution_type].present?
    collection = collection.where("YEAR(allocator.created) = ?", params[:year]) if params[:year].present?

    if params[:institution_type].present?
      institution_types = [{ id: params[:institution_type],
                             title: params[:institution_type].humanize,
                             count: collection.where(institution_type: params[:institution_type]).count }]
    else
      institution_types = collection.where.not(institution_type: nil).group(:institution_type).count
      institution_types = institution_types.map { |k,v| { id: k, title: k.humanize, count: v } }
    end

    if params[:region].present?
      regions = [{ id: params[:region],
                   title: REGIONS[params[:region].upcase],
                   count: collection.where(region: params[:region]).count }]
    else
      regions = collection.where.not(region: nil).group(:region).count
      regions = regions.map { |k,v| { id: k.downcase, title: REGIONS[k], count: v } }
    end

    if params[:year].present?
      years = [{ id: params[:year],
                 title: params[:year],
                 count: collection.where("YEAR(allocator.joined) = ?", params[:year]).count }]
    else
      years = collection.where.not(joined: nil).order("YEAR(allocator.joined) DESC").group("YEAR(allocator.joined)").count
      years = years.map { |k,v| { id: k.to_s, title: k.to_s, count: v } }
    end

    page = params[:page] || {}
    page[:number] = page[:number] && page[:number].to_i > 0 ? page[:number].to_i : 1
    page[:size] = page[:size] && (1..1000).include?(page[:size].to_i) ? page[:size].to_i : 25
    total = collection.count

    order = case params[:sort]
            when "-name" then "allocator.name DESC"
            when "created" then "allocator.created"
            when "-created" then "allocator.created DESC"
            else "allocator.name"
            end

    @providers = collection.order(order).page(page[:number]).per(page[:size])

    meta = { total: total,
             total_pages: @providers.total_pages,
             page: page[:number].to_i,
             regions: regions,
             years: years
           }

    render jsonapi: @providers, meta: meta, include: @include, each_serializer: MemberSerializer
  end

  def show
    render jsonapi: @provider, include: @include, serializer: MemberSerializer
  end

  protected

  # Use callbacks to share common setup or constraints between actions.
  def set_provider
    @provider = Provider.unscoped.where(symbol: params[:id]).first
    fail ActiveRecord::RecordNotFound unless @provider.present?
  end

  private

  def set_include
    if params[:include].present?
      @include = params[:include].split(",").map { |i| i.downcase.underscore }.join(",")
      @include = [@include]
    else
      @include = nil
    end
  end
end
