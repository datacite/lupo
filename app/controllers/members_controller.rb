class MembersController < ApplicationController
  before_action :set_provider, only: [:show]
  before_action :set_include

  def index
    page = (params.dig(:page, :number) || 1).to_i
    size = (params.dig(:page, :size) || 25).to_i
    from = (page - 1) * size

    sort = case params[:sort]
           when "-name" then { "name.keyword" => { order: 'desc' }}
           when "created" then { created: { order: 'asc' }}
           when "-created" then { created: { order: 'desc' }}
           else { "name.keyword" => { order: 'asc' }}
           end

    if params[:id].present?
      response = Provider.find_by_id(params[:id])
    elsif params[:ids].present?
      response = Provider.find_by_ids(params[:ids], from: from, size: size, sort: sort)
    else
      response = Provider.query(params[:query], year: params[:year], from: from, size: size, sort: sort)
    end

    total = response.results.total
    total_pages = (total.to_f / size).ceil
    years = total > 0 ? facet_by_year(response.response.aggregations.years.buckets) : nil

    #@providers = Kaminari.paginate_array(response.results, total_count: total).page(page).per(size)
    @providers = response.page(page).per(size).records

    meta = {
      total: total,
      total_pages: total_pages,
      page: page,
      years: years
    }

    render json: @providers, meta: meta, include: @include, each_serializer: MemberSerializer
  end

  def show
    render json: @provider, include: @include, serializer: MemberSerializer
  end

  protected

  # Use callbacks to share common setup or constraints between actions.
  def set_provider
    @provider = Provider.unscoped.where("allocator.role_name IN ('ROLE_ALLOCATOR', 'ROLE_MEMBER')").where(deleted_at: nil).where(symbol: params[:id]).first
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
