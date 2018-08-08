class EventsController < ApplicationController
  prepend_before_action :authenticate_user!
  before_action :set_doi
  before_action :set_include

  def index
    authorize! :read, @doi

    page = (params.dig(:page, :number) || 1).to_i
    size = (params.dig(:page, :size) || 25).to_i
    from = (page - 1) * size

    sort = case params[:sort]
           when "relevance" then { "_score" => { order: 'desc' }}
           when "total" then { "total" => { order: 'asc' }}
           when "-total" then { "total" => { order: 'desc' }}
           when "created" then { created_at: { order: 'asc' }}
           when "-created" then { created_at: { order: 'desc' }}
           else { "_doc" => { order: "asc" }}
           end

    if params[:id].present?
      response = Event.find_by_id(params[:id]) 
    elsif params[:ids].present?
      response = Event.find_by_ids(params[:ids], from: from, size: size, sort: sort)
    else
      response = Event.query(params[:query],
                             doi: @doi.doi,
                             source_id: params[:source_id], 
                             relation_type_id: params[:relation_type_id],
                             metric_type: params[:metric_type],
                             access_method: params[:access_method],
                             year_month: params[:year_month], 
                             from: from, 
                             size: size, 
                             sort: sort)
    end

    total = response.response.hits.total
    total_pages = (total.to_f / size).ceil
    year_months = total > 0 ? facet_by_year_month(response.response.aggregations.year_months.buckets) : nil
    sources = total > 0 ? facet_by_source(response.response.aggregations.sources.buckets) : nil
    relation_types = total > 0 ? facet_by_relation_type(response.response.aggregations.relation_types.buckets) : nil
    metric_types = total > 0 ? facet_by_metric_type(response.response.aggregations.metric_types.buckets) : nil
    access_methods = total > 0 ? facet_by_key(response.response.aggregations.access_methods.buckets) : nil

    @events = Kaminari.paginate_array(response.results, total_count: total).page(page).per(size)

    meta = {
      total: total,
      total_pages: total_pages,
      page: page,
      year_months: year_months,
      sources: sources,
      relation_types: relation_types,
      metric_types: metric_types,
      access_methods: access_methods
    }.compact

    render jsonapi: @events, meta: meta, include: @include
  end

  protected

  def set_doi
    @doi = Doi.where(doi: params[:doi_id]).first
    fail ActiveRecord::RecordNotFound unless @doi.present?
  end

  def set_include
    if params[:include].present?
      @include = params[:include].split(",").map { |i| i.downcase.underscore }.join(",")
      @include = [@include]
    else
      @include = ["doi"]
    end
  end
end
