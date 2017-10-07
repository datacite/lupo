class RepositoriesController < ApplicationController
  def index
    @repositories = Repository.where(params)
    render jsonapi: @repositories[:data], meta: @repositories[:meta]
  end

  def show
    @repository = Repository.where(id: params[:id])
    fail AbstractController::ActionNotFound unless @repository.present?

    render jsonapi: @repository[:data]
  end

  def badge
    id = "http://www.re3data.org/public/badges/s/light/" + params[:id][3..-1]
    result = Maremma.get(id, accept: "image/svg+xml", raw: true)
    render body: result.body.fetch("data", nil), content_type: "image/svg+xml"
  end
end
