require 'uri'

class DoisController < ApplicationController
  before_action :set_doi, only: [:show, :update, :destroy]
  before_action :set_include
  before_action :authenticate_user_from_token!
  load_and_authorize_resource :except => [:index, :show]

  def index
    @dois = DoiSearch.where(params)
    render jsonapi: @dois[:data], meta: @dois[:meta], include: @include, each_serializer: DoiSerializer
  end

  def show
    render jsonapi: @doi, include: @include, serializer: DoiSerializer
  end

  def create
    @doi = Doi.new(safe_params)
    authorize! :create, @doi

    if @doi.save
      render jsonapi: @doi, status: :created, location: @doi
    else
      Rails.logger.warn @doi.errors.inspect
      render jsonapi: serialize(@doi.errors), status: :unprocessable_entity
    end
  end

  def update
    if @doi.update_attributes(safe_params)
      render jsonapi: @provider
    else
      Rails.logger.warn @doi.errors.inspect
      render jsonapi: serialize(@doi.errors), status: :unprocessable_entity
    end
  end

  # don't delete, but set deleted_at timestamp
  def destroy
    if @doi.update_attributes(is_active: "\x00", deleted_at: Time.zone.now)
      head :no_content
    else
      Rails.logger.warn @doi.errors.inspect
      render jsonapi: serialize(@doi.errors), status: :unprocessable_entity
    end
  end

  protected

  def set_doi
    @doi = Doi.where(doi: params[:id]).first
    fail ActiveRecord::RecordNotFound unless @doi.present?
  end

  def set_include
    if params[:include].present?
      @include = params[:include].split(",").map { |i| i.downcase.underscore }.join(",")
      @include = [@include]
    else
      @include = ["client,provider,resource_type"]
    end
  end

  private

  def safe_params
    fail JSON::ParserError, "You need to provide a payload following the JSONAPI spec" unless params[:data].present?
    Rails.logger.warn params
    ActiveModelSerializers::Deserialization.jsonapi_parse!(
      params, only: [:uid, :created, :doi, :is_active, :version, :client]
    )
  end
end
