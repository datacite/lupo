# frozen_string_literal: true

class ClientsController < ApplicationController
  include Countable

  before_action :set_client, only: %i[show update destroy]
  before_action :authenticate_user!
  before_action :set_include
  load_and_authorize_resource except: %i[index show totals stats]

  def index
    sort =
      case params[:sort]
      when "relevance"
        { "_score" => { order: "desc" } }
      when "name"
        { "name.raw" => { order: "asc" } }
      when "-name"
        { "name.raw" => { order: "desc" } }
      when "created"
        { created: { order: "asc" } }
      when "-created"
        { created: { order: "desc" } }
      else
        { "name.raw" => { order: "asc" } }
      end

    page = page_from_params(params)

    response =
      if params[:id].present?
        Client.find_by_id(params[:id])
      elsif params[:ids].present?
        Client.find_by_id(params[:ids], page: page, sort: sort)
      else
        Client.query(
          params[:query],
          year: params[:year],
          from_date: params[:from_date],
          until_date: params[:until_date],
          provider_id: params[:provider_id],
          re3data_id: params[:re3data_id],
          opendoar_id: params[:opendoar_id],
          software: params[:software],
          certificate: params[:certificate],
          repository_type: params[:repository_type],
          client_type: params[:client_type],
          page: page,
          sort: sort,
        )
      end

    begin
      total = response.results.total
      total_pages = page[:size] > 0 ? (total.to_f / page[:size]).ceil : 0
      years =
        if total > 0
          facet_by_key_as_string(response.aggregations.years.buckets)
        end
      providers =
        if total.positive?
          facet_by_combined_key(response.aggregations.providers.buckets)
        end
      software =
        if total.positive?
          facet_by_software(response.aggregations.software.buckets)
        end
      client_types =
        if total.positive?
          facet_by_client_type(response.aggregations.client_types.buckets)
        end
      certificates =
         if total.positive?
           facet_by_key(response.aggregations.certificates.buckets)
         end
      repository_types =
        if total.positive?
          facet_by_key(response.aggregations.repository_types.buckets)
        end

      @clients = response.results

      options = {}
      options[:meta] = {
        total: total,
        "totalPages" => total_pages,
        page: page[:number],
        years: years,
        providers: providers,
        software: software,
        certificates: certificates,
        repository_types: repository_types,
        "clientTypes" => client_types,
      }.compact

      options[:links] = {
        self: request.original_url,
        next:
          if @clients.blank? || page[:number] == total_pages
            nil
          else
            request.base_url + "/clients?" +
              {
                query: params[:query],
                "provider-id" => params[:provider_id],
                software: params[:software],
                certificate: params[:certificate],
                "repositoryType" => params[:repository_type],
                "clientTypes" => params[:client_type],
                year: params[:year],
                "page[number]" => page[:number] + 1,
                "page[size]" => page[:size],
                sort: params[:sort],
                fields: fields_hash_from_params(params)
              }.compact.
              to_query
          end,
      }.compact
      options[:include] = @include
      options[:is_collection] = true
      options[:params] = { current_ability: current_ability }

      fields = fields_from_params(params)
      if fields
        render(
          json: ClientSerializer.new(@clients, options.merge(fields: fields)).serializable_hash.to_json,
          status: :ok
        )
      else
        render(
          json: ClientSerializer.new(@clients, options).serializable_hash.to_json,
          status: :ok
        )
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

    render(
      json: ClientSerializer.new(@client, options).serializable_hash.to_json,
      status: :ok
    )
  end

  def create
    @client = Client.new(safe_params)
    authorize! :create, @client

    if @client.save
      @client.send_welcome_email(responsible_id: current_user.uid)
      options = {}
      options[:is_collection] = false
      options[:params] = { current_ability: current_ability, detail: true }

      render(
        json: ClientSerializer.new(@client, options).serializable_hash.to_json,
        status: :created
      )
    else
      # Rails.logger.error @client.errors.inspect
      render json: serialize_errors(@client.errors, uid: @client.uid),
             status: :unprocessable_entity
    end
  end

  def update
    options = {}
    options[:is_collection] = false
    options[:params] = { current_ability: current_ability, detail: true }

    if params.dig(:data, :attributes, :mode) == "transfer"
      # only update provider_id
      authorize! :transfer, @client

      @client.transfer(provider_target_id: safe_params[:target_id])
      render(
        json: ClientSerializer.new(@client, options).serializable_hash.to_json,
        status: :ok
      )
    elsif @client.update(safe_params)
      render(
        json: ClientSerializer.new(@client, options).serializable_hash.to_json,
        status: :ok
      )
    else
      # Rails.logger.error @client.errors.inspect
      render json: serialize_errors(@client.errors, uid: @client.uid),
             status: :unprocessable_entity
    end
  end

  # don't delete, but set deleted_at timestamp
  # a client with dois or prefixes can't be deleted
  def destroy
    if @client.dois.present?
      message = "Can't delete client that has DOIs."
      status = 400
      Rails.logger.warn message
      render json: {
        errors: [{ status: status.to_s, title: message }],
      }.to_json,
             status: status
    elsif @client.update(is_active: nil, deleted_at: Time.zone.now)
      unless Rails.env.test?
        @client.send_delete_email(responsible_id: current_user.uid)
      end
      head :no_content
    else
      # Rails.logger.error @client.errors.inspect
      render json: serialize_errors(@client.errors, uid: @client.uid),
             status: :unprocessable_entity
    end
  end

  def totals
    page = { size: 0, number: 1 }
    state =
      if current_user.present? && current_user.is_admin_or_staff? &&
          params[:state].present?
        params[:state]
      else
        "registered,findable"
      end
    response =
      DataciteDoi.query(
        nil,
        provider_id: params[:provider_id],
        state: state,
        page: page,
        totals_agg: "client",
      )
    registrant =
      if response.results.total.positive?
        clients_totals(response.aggregations.clients_totals.buckets)
      else
        []
      end

    render json: registrant, status: :ok
  end

  def stats
    meta = {
      dois:
        doi_count(
          client_id:
            # downloads: download_count(client_id: params[:id]),
            params[
              :id
            ],
        ),
      "resourceTypes" => resource_type_count(client_id: params[:id]),
    }.compact

    render json: meta, status: :ok
  end

  protected
    def set_include
      if params[:include].present?
        @include =
          params[:include].split(",").map { |i| i.downcase.underscore.to_sym }
        @include = @include & %i[provider repository]
      else
        @include = []
      end
    end

    def set_client
      @client = Client.where(symbol: params[:id]).where(deleted_at: nil).first
      fail ActiveRecord::RecordNotFound if @client.blank?
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
          :symbol,
          :name,
          "systemEmail",
          "contactEmail",
          "globusUuid",
          :domains,
          :provider,
          :url,
          "repositoryType",
          { "repositoryType" => [] },
          :description,
          :language,
          { language: [] },
          "alternateName",
          :software,
          "targetId",
          "isActive",
          "passwordInput",
          "clientType",
          :re3data,
          :opendoar,
          :issn,
          { issn: %i[issnl electronic print] },
          :certificate,
          { certificate: [] },
          "serviceContact",
          { "serviceContact": [:email, "givenName", "familyName"] },
          "salesforceId",
          "fromSalesforce",
        ],
        keys: {
          "systemEmail" => :system_email,
          "contactEmail" => :system_email,
          "globusUuid" => :globus_uuid,
          "salesforceId" => :salesforce_id,
          "fromSalesforce" => :from_salesforce,
          "targetId" => :target_id,
          "isActive" => :is_active,
          "passwordInput" => :password_input,
          "clientType" => :client_type,
          "alternateName" => :alternate_name,
          "repositoryType" => :repository_type,
          "serviceContact" => :service_contact,
        },
      )
    end
end
