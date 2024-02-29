# frozen_string_literal: true

class WorksController < ApplicationController
  before_action :set_doi, only: %i[show]
  before_action :set_include, only: %i[index show]

  def index
    sort =
      case params[:sort]
      when "name"
        { "doi" => { order: "asc" } }
      when "-name"
        { "doi" => { order: "desc" } }
      when "created"
        { created: { order: "asc" } }
      when "-created"
        { created: { order: "desc" } }
      when "updated"
        { updated: { order: "asc" } }
      when "-updated"
        { updated: { order: "desc" } }
      when "relevance"
        { "_score": { "order": "desc" } }
      else
        { updated: { order: "desc" } }
      end

    page = page_from_params(params)

    sample_group_field =
      case params[:sample_group]
      when "client"
        "client_id"
      when "data-center"
        "client_id"
      when "provider"
        "provider_id"
      when "resource-type"
        "types.resourceTypeGeneral"
      end

    response = if params[:id].present?
      DataciteDoi.find_by_id(params[:id])
    elsif params[:ids].present?
      DataciteDoi.find_by_ids(params[:ids], page: page, sort: sort)
    else
      DataciteDoi.query(
        params[:query],
        state: "findable",
        exclude_registration_agencies: true,
        created: params[:created],
        registered: params[:registered],
        provider_id: params[:member_id],
        client_id: params[:data_center_id],
        affiliation_id: params[:affiliation_id],
        prefix: params[:prefix],
        user_id: params[:person_id],
        resource_type_id: params[:resource_type_id],
        has_citations: params[:has_citations],
        has_views: params[:has_views],
        has_downloads: params[:has_downloads],
        schema_version: params[:schema_version],
        sample_group: sample_group_field,
        sample_size: params[:sample],
        page: page,
        sort: sort,
        random: params[:sample].present? ? true : false,
      )
    end

    begin
      total = response.results.total
      total_pages =
        if page[:size].positive?
          ([total.to_f, 10_000].min / page[:size]).ceil
        else
          0
        end

      resource_types =
        if total.positive?
          facet_by_combined_key(
            response.response.aggregations.resource_types.buckets,
          )
        end
      registered =
        if total.positive?
          facet_by_year(response.response.aggregations.registered.buckets)
        end
      providers =
        if total.positive?
          facet_by_combined_key(
            response.response.aggregations.providers.buckets,
          )
        end
      clients =
        if total.positive?
          facet_by_combined_key(response.response.aggregations.clients.buckets)
        end
      affiliations =
        if total.positive?
          facet_by_combined_key(
            response.response.aggregations.affiliations.buckets,
          )
        end

      @dois = response.results

      options = {}
      options[:meta] = {
        "resource-types" => resource_types,
        registered: registered,
        providers: providers,
        "data-centers" => clients,
        affiliations: affiliations,
        total: total,
        "total-pages" => total_pages,
        page: page[:number],
      }.compact

      options[:include] = @include
      options[:is_collection] = true
      options[:links] = nil
      options[:params] = { current_ability: current_ability }

      # If we're using sample groups we need to unpack the results from the aggregation bucket hits.
      if sample_group_field.present?
        sample_dois = []
        response.response.aggregations.samples.buckets.each do |bucket|
          bucket.samples_hits.hits.hits.each do |hit|
            sample_dois << hit._source
          end
        end
      end

      # Results to return are either our sample group dois or the regular hit results
      @dois = sample_dois || response.results

      render(
        json: WorkSerializer.new(@dois, options).serializable_hash.to_json,
        status: :ok
      )
    rescue Elasticsearch::Transport::Transport::Errors::BadRequest => e
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
    options[:params] = { current_ability: current_ability, detail: true }

    render(
      json: WorkSerializer.new(@doi, options).serializable_hash.to_json,
      status: :ok
    )
  end

  protected
    def set_doi
      @doi =
        DataciteDoi.where(doi: params[:id]).where(aasm_state: "findable").first

      fail ActiveRecord::RecordNotFound if @doi.blank?
    end

    def set_include
      if params[:include].present?
        include_keys = {
          "data_center" => :client,
          "member" => :provider,
          "resource_type" => :resource_type,
        }
        @include =
          params[:include].split(",").reduce([]) do |sum, i|
            k = include_keys[i.downcase.underscore]
            sum << k if k.present?
            sum
          end
      else
        @include = []
      end
    end
end
