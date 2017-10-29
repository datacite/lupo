class ResourceTypesController < ApplicationController
  def index
    @resource_types = ResourceType.where(params)
    render jsonapi: @resource_types[:data], meta: @resource_types[:meta]
  end

  def show
    @resource_type = ResourceType.where(id: params[:id])
    fail AbstractController::ActionNotFound unless @resource_type.present?

    render jsonapi: @resource_type[:data]
  end
end
