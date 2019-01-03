class MembersController < ApplicationController
  before_action :set_provider, only: [:show]

  def index
    sort = case params[:sort]
           when "relevance" then { "_score" => { order: 'desc' }}
           when "name" then { "name.raw" => { order: 'asc' }}
           when "-name" then { "name.raw" => { order: 'desc' }}
           when "created" then { created: { order: 'asc' }}
           when "-created" then { created: { order: 'desc' }}
           else { "name.raw" => { order: 'asc' }}
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
      response = Provider.find_by_id(params[:id])
    elsif params[:ids].present?
      response = Provider.find_by_ids(params[:ids], page: page, sort: sort)
    else
      response = Provider.query(params[:query], all_members: true, year: params[:year], region: params[:region], organization_type: params[:organization_type], focus_area: params[:focus_area], fields: params[:fields], page: page, sort: sort)
    end

    begin
      total = response.results.total
      total_pages = page[:size] > 0 ? (total.to_f / page[:size]).ceil : 0
      years = total > 0 ? facet_by_year(response.response.aggregations.years.buckets) : nil
      regions = total > 0 ? facet_by_region(response.response.aggregations.regions.buckets) : nil
      organization_types = total > 0 ? facet_by_key(response.response.aggregations.organization_types.buckets) : nil
      focus_areas = total > 0 ? facet_by_key(response.response.aggregations.focus_areas.buckets) : nil

      @members = response.results.results

      options = {}
      options[:meta] = {
        total: total,
        "total-pages" => total_pages,
        page: page[:number],
        years: years,
        regions: regions,
        "organization-types" => organization_types,
        "focus-areas" => focus_areas
      }.compact

      options[:links] = {
        self: request.original_url,
        next: @members.blank? ? nil : request.base_url + "/members?" + {
          query: params[:query],
          year: params[:year],
          region: params[:region],
          "organization-type" => params[:organization_type],
          "focus-area" => params[:focus_area],
          fields: params[:fields],
          "page[number]" => params.dig(:page, :number),
          "page[size]" => params.dig(:page, :size),
          sort: sort }.compact.to_query
        }.compact
      options[:include] = @include
      options[:is_collection] = true
      options[:links] = nil

      render json: MemberSerializer.new(@members, options).serialized_json, status: :ok
    rescue Elasticsearch::Transport::Transport::Errors::BadRequest => exception
      Bugsnag.notify(exception)

      message = JSON.parse(exception.message[6..-1]).to_h.dig("error", "root_cause", 0, "reason")

      render json: { "errors" => { "title" => message }}.to_json, status: :bad_request
    end
  end

  def show
    options = {}
    options[:include] = @include
    options[:is_collection] = false

    render json: MemberSerializer.new(@provider, options).serialized_json, status: :ok
  end

  protected

  # Use callbacks to share common setup or constraints between actions.
  def set_provider
    @provider = Provider.unscoped.where("allocator.role_name IN ('ROLE_ALLOCATOR', 'ROLE_MEMBER')").where(deleted_at: nil).where(symbol: params[:id]).first
    fail ActiveRecord::RecordNotFound unless @provider.present?
  end
end
