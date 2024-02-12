# frozen_string_literal: true

class ResourceTypesController < ApplicationController
  def index
    @resource_types = ResourceType.where(params)

    options = {}
    options[:meta] = {
      total: @resource_types.dig(:meta, :total),
      "total-pages" => 1,
      page: @resource_types.dig(:meta, :page),
    }.compact
    options[:is_collection] = true

    render(
      json: ResourceTypeSerializer.new(@resource_types[:data], options).serialized_json,
      status: :ok
    )
  end

  def show
    @resource_type = ResourceType.where(id: params[:id])
    fail AbstractController::ActionNotFound if @resource_type.blank?

    options = {}
    options[:is_collection] = false

    render(
      json: ResourceTypeSerializer.new(@resource_type[:data], options).serialized_json,
      status: :ok
    )
  end
end
