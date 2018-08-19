class RepositoriesController < ApplicationController
  def index
    @repositories = Repository.where(params)

    options = {}
    options[:meta] = {
      total: @repositories.dig(:meta, :total),
      "total-pages" => @repositories.dig(:meta, :total_pages),
      page: @repositories.dig(:meta, :page)
    }.compact

    options[:links] = {
      self: request.original_url,
      next: @repositories[:data].blank? ? nil : request.base_url + "/repositories?" + {
        "page[number]" => params.dig(:page, :number).to_i + 1,
        "page[size]" => params.dig(:page, :size),
        sort: params[:sort] }.compact.to_query
      }.compact
    options[:include] = @include
    options[:is_collection] = true

    render json: RepositorySerializer.new(@repositories[:data], options).serialized_json, status: :ok
  end

  def show
    @repository = Repository.where(id: params[:id])
    fail AbstractController::ActionNotFound unless @repository.present?

    options = {}
    options[:is_collection] = false

    render json: RepositorySerializer.new(@repository[:data], options).serialized_json, status: :ok
  end

  def badge
    id = "http://www.re3data.org/public/badges/s/light/" + params[:id][3..-1]
    result = Maremma.get(id, accept: "image/svg+xml", raw: true)
    render body: result.body.fetch("data", nil), content_type: "image/svg+xml"
  end
end
