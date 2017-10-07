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
end
