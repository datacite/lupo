class WorksController < ApplicationController
  before_action :set_doi, only: [:show]
  before_action :set_include

  def index
    params[:client_id] = params.delete(:data_center_id)
    params[:provider_id] = params.delete(:member_id)
    params[:doi_id] = params.delete(:work_id)

    @dois = DoiSearch.where(params)
    @dois[:meta]["data-centers"] = @dois[:meta].delete("clients")
    @dois[:meta] = @dois[:meta].except("states")

    render jsonapi: @dois[:data], meta: @dois[:meta], include: @include, each_serializer: WorkSerializer
  end

  def show
    render jsonapi: @doi, include: @include, serializer: WorkSerializer
  end

  protected

  def set_doi
    params[:client_id] = params.delete(:data_center_id)
    params[:provider_id] = params.delete(:member_id)

    @doi = DoiSearch.where(id: params[:id])[:data].first
    fail ActiveRecord::RecordNotFound unless @doi.present?
  end

  def set_include
    if params[:include].present?
      @include = params[:include].split(",").map { |i| i.downcase.underscore }.join(",")
      @include = [@include]
    else
      @include = nil
    end
  end
end
