class PrefixesController < ApplicationController
  before_action :set_prefix, only: [:show, :update, :destroy]
  before_action :authenticate_user!
  before_action :set_include
  load_and_authorize_resource :except => [:index, :show]

  def index
    page = (params.dig(:page, :number) || 1).to_i
    size = (params.dig(:page, :size) || 25).to_i
    from = (page - 1) * size

    sort = case params[:sort]
           when "name" then { "name.keyword" => { order: 'asc' }}
           when "-name" then { "name.keyword" => { order: 'desc' }}
           when "created" then { created: { order: 'asc' }}
           else { created: { order: 'desc' }}
           end

    if params[:id].present?
      response = Prefix.find_by_id(params[:id]) 
    else
      response = Prefix.query(params[:query], year: params[:year], provider_id: params[:provider_id], from: from, size: size, sort: sort)
    end

    total = response.results.total
    total_pages = (total.to_f / size).ceil
    years = total > 0 ? facet_by_year(response.response.aggregations.years.buckets) : nil
    providers = total > 0 ? facet_by_provider_ids(response.response.aggregations.providers.buckets) : nil

    #@clients = Kaminari.paginate_array(response.results, total_count: total).page(page).per(size)
    @prefixes = response.page(page).per(size).records

    meta = {
      total: total,
      total_pages: total_pages,
      page: page,
      years: years,
      providers: providers
    }.compact

    render jsonapi: @prefixes, meta: meta, include: @include
  end

  def show
    render jsonapi: @prefix, include: @include, serializer: PrefixSerializer
  end

  def create
    @prefix = Prefix.new(safe_params)
    authorize! :create, @prefix

    if @prefix.save
      render jsonapi: @prefix, status: :created, location: @prefix
    else
      Rails.logger.warn @prefix.errors.inspect
      render jsonapi: serialize(@prefix.errors), status: :unprocessable_entity
    end
  end

  def update
    response.headers["Allow"] = "HEAD, GET, POST, DELETE, OPTIONS"
    render json: { errors: [{ status: "405", title: "Method not allowed" }] }.to_json, status: :method_not_allowed
  end

  def destroy
    @prefix.destroy
  end

  protected

  def set_include
    if params[:include].present?
      @include = params[:include].split(",").map { |i| i.downcase.underscore }.join(",")
      @include = [@include]
    else
      # always include because Ember pagination doesn't (yet) understand include parameter
      @include = ['clients','providers']
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_prefix
    @prefix = Prefix.where(prefix: params[:id]).first

    # fallback to call handle server, i.e. for prefixes not from DataCite
    @prefix = Handle.where(id: params[:id]) unless @prefix.present? ||  Rails.env.test?
    fail ActiveRecord::RecordNotFound unless @prefix.present?
  end

  def safe_params
    ActiveModelSerializers::Deserialization.jsonapi_parse!(
      params, only: [:id, :created],
              keys: { id: :prefix }
    )
  end
end
