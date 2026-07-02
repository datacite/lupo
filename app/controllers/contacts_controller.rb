# frozen_string_literal: true

class ContactsController < ApplicationController
  include ActionController::MimeResponds

  before_action :set_contact, only: %i[show update destroy]
  before_action :authenticate_user!
  before_action :set_include

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
              if @contacts.blank? || page[:number] == total_pages
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

          render(
            json: ContactSerializer.new(@contacts, options).serializable_hash.to_json,
            status: :ok
          )
        end
      end
    rescue Elastic::Transport::Transport::Errors::BadRequest => e

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

    render(
      json: ContactSerializer.new(@contact, options).serializable_hash.to_json,
      status: :ok
    )
  end

  def create
    @contact = Contact.new(safe_params)
    authorize! :create, @contact

    @contact.role_name = [] if @contact.role_name.nil?

    if @contact.save
      options = {}
      options[:include] = @include
      options[:is_collection] = false
      options[:params] = { current_ability: current_ability, detail: true }

      @contact.set_provider_contacts

      render(
        json: ContactSerializer.new(@contact, options).serializable_hash.to_json,
        status: :created
      )
    else
      # Rails.logger.error @contact.errors.inspect
      render json: serialize_errors(@contact.errors, uid: @contact.uid),
             status: :unprocessable_entity
    end
  end

  def update
    @contact.assign_attributes(safe_params)
    @contact.role_name = [] if @contact.role_name.nil?

    if @contact.save
      options = {}
      options[:include] = @include
      options[:is_collection] = false
      options[:params] = { current_ability: current_ability, detail: true }

      @contact.set_provider_contacts

      render(
        json: ContactSerializer.new(@contact, options).serializable_hash.to_json,
        status: :ok
      )
    else
      # Rails.logger.error @contact.errors.inspect
      render json: serialize_errors(@contact.errors, uid: @contact.uid),
             status: :unprocessable_entity
    end
  end

  # don't delete, but set deleted_at timestamp
  def destroy
    if @contact.update(deleted_at: Time.zone.now)
      remove_provider_contacts
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
=begin
    def set_provider_contacts
      if @contact.valid? && @contact.provider.present?
        contacts = @contact.provider.contacts.where(deleted_at: nil)
        provider = @contact.provider

        # Make sure no other contact with this provider claims these roles.
        contacts.each do | contact |
          if !@contact.is_me?(contact)
            old_role_name = contact.role_name.present? ? contact.role_name : []
            new_role_name = (contact.role_name.present? ? contact.role_name : []) - (@contact.role_name.present? ? @contact.role_name : [])
            if old_role_name.sort != new_role_name.sort
              contact.update_column("role_name", new_role_name)
            end
          end
        end

        # Clear provider role associations.
        Contact.roles.each do | role |
          @contact.set_provider_role!(role, nil)
        end

        # Reset provider role associations.
        contacts.each do |contact|
          contact&.role_name&.each do | role |
            if contact.has_role?(role)
              contact.set_provider_role!(role, { 'email': contact.email || nil, 'given_name': contact.given_name || nil, 'family_name': contact.family_name || nil })
            end
          end
        end

        # Send provider export message. (Ignore if record was created/updated via Salesforce API)
        provider.save
        provider.send_provider_export_message(provider.to_jsonapi.merge(slack_output: true)) if !provider.from_salesforce && (Rails.env.production? || ENV["SQS_PREFIX"] == "stage")

        # Send contact export messages. (Ignore if record was created/updated via Salesforce API)
        contacts.each do |contact|
          contact.save
          contact.send_contact_export_message(contact.to_jsonapi.merge(slack_output: true)) if !contact.from_salesforce && (Rails.env.production? || ENV["SQS_PREFIX"] == "stage")
        end
      end
    end
=end

    def remove_provider_contacts
      Array.wrap(@contact.role_name).each do | role |
        if @contact.has_provider_role?(role)
          @contact.set_provider_role!(role, nil)
        end
      end
      @contact.role_name = []

      @contact.provider.save
      @contact.provider.send_provider_export_message(@contact.provider.to_jsonapi.merge(slack_output: true)) if !@contact.provider.from_salesforce && (Rails.env.production? || ENV["SQS_PREFIX"] == "stage")

      @contact.save
      @contact.send_contact_export_message(@contact.to_jsonapi.merge(slack_output: true)) if !@contact.from_salesforce && (Rails.env.production? || ENV["SQS_PREFIX"] == "stage")
    end

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
