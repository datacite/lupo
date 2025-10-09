# frozen_string_literal: true

class ReferenceRepositoriesController < ApplicationController
  include Countable

  before_action :set_repository, only: %i[show]
  before_action :authenticate_user!
  load_and_authorize_resource except: %i[index show]

  def index
    sort = { "_score" => { order: "desc" } }

    page = page_from_params(params)

    response =
      if params[:id].present?
        ReferenceRepository.find_by_id(params[:id])
      elsif params[:ids].present?
        ReferenceRepository.find_by_id(params[:ids], page: page, sort: sort)
      else
        ReferenceRepository.query(
          params[:query],

          year: params[:year],
          certificate: params[:certificate],
          software: params[:software],
          has_pid: params[:has_pid],
          is_open: params[:is_open],
          is_certified: params[:is_certified],
          subject_id: params[:subject_id],
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
      certificates =
         if total.positive?
           facet_by_key(response.aggregations.certificates.buckets)
         end
      repository_types =
        if total.positive?
          facet_by_key(response.aggregations.repository_types.buckets)
        end

      repositories = response.results

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
      }.compact

      options[:links] = {
        self: request.original_url,
        next:
          if repositories.blank? || page[:number] == total_pages
            nil
          else
            request.base_url + "/reference-repositories?" +
              {
                query: params[:query],
                software: params[:software],
                certificate: params[:certificate],
                year: params[:year],
                "page[number]" => page[:number] + 1,
                "page[size]" => page[:size],
                sort: params[:sort],
              }.compact.
              to_query
          end,
      }.compact
      options[:is_collection] = true
      options[:params] = { current_ability: current_ability }

      render(
        json: ReferenceRepositorySerializer.new(repositories, options).serializable_hash.to_json,
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
    options[:is_collection] = false
    options[:params] = { current_ability: current_ability }

    render(
      json: ReferenceRepositorySerializer.new(@repository, options).serializable_hash.to_json,
      status: :ok
    )
  end


  protected
    def set_repository
      response = ReferenceRepository.find_by_id(params[:id])
      @repository = response.respond_to?(:results) ? response.results.first : response
      fail ActiveRecord::RecordNotFound if @repository.blank?
    end
end
