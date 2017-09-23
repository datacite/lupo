class WorksController < ApplicationController
  before_action :set_doi, only: [:show]
  before_action :set_include

  def index
    @dois = Doi.where(params)
    @dois[:meta]["data-centers"] = @dois[:meta].delete("clients")
    render jsonapi: @dois[:data], meta: @dois[:meta], include: @include, each_serializer: WorkSerializer
  end

  def show
    render jsonapi: @doi[:data], include: @include, serializer: WorkSerializer
  end

  protected

  def set_doi
    @doi = Doi.where(params)
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
