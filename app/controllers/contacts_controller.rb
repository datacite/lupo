# frozen_string_literal: true

class ContactsController < ApplicationController
  include ActionController::MimeResponds

  before_action :set_contact, only: %i[show update destroy]
  before_action :authenticate_user!
  load_and_authorize_resource

  def index
    sort =
      case params[:sort]
      when "relevance"
        { "_score" => { order: "desc" } }
      when "name"
        { "family_name" => { order: "asc" } }
      when "-name"
        { "family_name" => { order: "desc" } }
      when "created"
        { created_at: { order: "asc" } }
      when "-created"
        { created_at: { order: "desc" } }
      else
        { "family_name" => { order: "asc" } }
      end

    page = page_from_params(params)

    response = if params[:id].present?
      Contact.find_by_id(params[:id])
    else
      Contact.query(
        params[:query],
        role_name: params[:role_name],
        provider_id: params[:provider_id],
        consortium_id: params[:consortium_id],
        include_deleted: params[:include_deleted],
        page: page,
        sort: sort,
      )
    end

    begin
      total = response.results.total
      total_pages = page[:size] > 0 ? (total.to_f / page[:size]).ceil : 0

      roles =
        if total > 0
          facet_by_key(response.aggregations.roles.buckets)
        end

      @contacts = response.results
      respond_to do |format|
        format.json do
          options = {}
          options[:meta] = {
            total: total,
            "totalPages" => total_pages,
            page: page[:number],
            roles: roles,
          }.compact

          options[:links] = {
            self: request.original_url,
            next:
              if @contacts.blank?
                nil
              else
                request.base_url + "/contacts?" +
                  {
                    query: params[:query],
                    role: params[:role],
                    "page[number]" => page[:number] + 1,
                    "page[size]" => page[:size],
                    sort: sort,
                  }.compact.
                  to_query
              end,
          }.compact
          options[:include] = @include
          options[:is_collection] = true
          options[:params] = { current_ability: current_ability }

          render json:
                    ContactSerializer.new(@contacts, options).
                      serialized_json,
                  status: :ok
        end
      end
    rescue Elasticsearch::Transport::Transport::Errors::BadRequest => e
      Raven.capture_exception(e)

      message =
        JSON.parse(e.message[6..-1]).to_h.dig(
          "error",
          "root_cause",
          0,
          "reason",
        )

      render json: { "errors" => { "title" => message } }.to_json,
             status: :bad_request
    end
  end

  def show
    options = {}
    options[:include] = @include
    options[:is_collection] = false
    options[:params] = { current_ability: current_ability }

    render json: ContactSerializer.new(@contact, options).serialized_json,
           status: :ok
  end

  def create
    @contact = Contact.new(safe_params)
    authorize! :create, @contact

    if @contact.save
      options = {}
      options[:include] = @include
      options[:is_collection] = false
      options[:params] = { current_ability: current_ability }

      render json: ContactSerializer.new(@contact, options).serialized_json,
             status: :created
    else
      # Rails.logger.error @contact.errors.inspect
      render json: serialize_errors(@contact.errors, uid: @contact.uid),
             status: :unprocessable_entity
    end
  end

  def update
    if @contact.update(safe_params)
      options = {}
      options[:include] = @include
      options[:is_collection] = false
      options[:params] = { current_ability: current_ability }

      render json: ContactSerializer.new(@contact, options).serialized_json,
             status: :ok
    else
      # Rails.logger.error @contact.errors.inspect
      render json: serialize_errors(@contact.errors, uid: @contact.uid),
             status: :unprocessable_entity
    end
  end

  # don't delete, but set deleted_at timestamp
  def destroy
    if @contact.update(deleted_at: Time.zone.now)
      head :no_content
    else
      # Rails.logger.error @contact.errors.inspect
      render json: serialize_errors(@contact.errors, uid: @contact.uid),
             status: :unprocessable_entity
    end
  end

  def export
    response = Contact.export(query: params[:query])
    render json: { "message" => response }, status: :ok
  end

  protected
    def set_contact
      @contact = Contact.where(uid: params[:id]).where(deleted_at: nil).first
      fail ActiveRecord::RecordNotFound if @contact.blank?
    end

    def set_include
      if params[:include].present?
        @include =
          params[:include].split(",").map { |i| i.downcase.underscore.to_sym }
        @include = @include & %i[provider]
      else
        @include = []
      end
    end

  private
    def safe_params
      if params[:data].blank?
        fail JSON::ParserError,
             "You need to provide a payload following the JSONAPI spec"
      end

      ActiveModelSerializers::Deserialization.jsonapi_parse!(
        params,
        only: [
          :uid,
          :givenName,
          :familyName,
          :email,
          :roleName,
          { roleName: [] },
          :provider,
          "fromSalesforce",
        ],
        keys: {
          "givenName" => :given_name,
          "familyName" => :family_name,
          "roleName" => :role_name,
          "fromSalesforce" => :from_salesforce,
        },
      )
    end
end
