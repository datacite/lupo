# frozen_string_literal: true

class MembersController < ApplicationController
  before_action :set_provider, only: %i[show]

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

    response = if params[:id].present?
      Provider.find_by_id(params[:id])
    elsif params[:ids].present?
      Provider.find_by_id(params[:ids], page: page, sort: sort)
    else
      Provider.query(
        params[:query],
        year: params[:year],
        region: params[:region],
        organization_type: params[:organization_type],
        focus_area: params[:focus_area],
        fields: params[:fields],
        page: page,
        sort: sort,
      )
    end

    begin
      total = response.results.total
      total_pages = page[:size] > 0 ? (total.to_f / page[:size]).ceil : 0
      years =
        if total > 0
          facet_by_year(response.response.aggregations.years.buckets)
        end
      regions =
        if total > 0
          facet_by_region(response.response.aggregations.regions.buckets)
        end
      organization_types =
        if total > 0
          facet_by_key(
            response.response.aggregations.organization_types.buckets,
          )
        end
      focus_areas =
        if total > 0
          facet_by_key(response.response.aggregations.focus_areas.buckets)
        end

      @members = response.results

      options = {}
      options[:meta] = {
        total: total,
        "total-pages" => total_pages,
        page: page[:number],
        years: years,
        regions: regions,
        "organization-types" => organization_types,
        "focus-areas" => focus_areas,
      }.compact

      options[:links] = {
        self: request.original_url,
        next:
          if @members.blank? || page[:number] == total_pages
            nil
          else
            request.base_url + "/members?" +
              {
                query: params[:query],
                year: params[:year],
                region: params[:region],
                "organization-type" => params[:organization_type],
                "focus-area" => params[:focus_area],
                fields: params[:fields],
                "page[number]" => page[:number] + 1,
                "page[size]" => page[:size],
                sort: sort,
              }.compact.
              to_query
          end,
      }.compact
      options[:include] = @include
      options[:is_collection] = true
      options[:links] = nil

      render(
        json: MemberSerializer.new(@members, options).serialized_json,
        status: :ok
      )
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

    render(
      json: MemberSerializer.new(@provider, options).serialized_json,
      status: :ok
    )
  end

  protected
    def set_provider
      @provider =
        Provider.unscoped.where(
          "allocator.role_name IN ('ROLE_FOR_PROFIT_PROVIDER', 'ROLE_CONTRACTUAL_PROVIDER', 'ROLE_CONSORTIUM' , 'ROLE_CONSORTIUM_ORGANIZATION', 'ROLE_ALLOCATOR', 'ROLE_MEMBER', 'ROLE_DEV')",
        ).
          where(deleted_at: nil).
          where(symbol: params[:id]).
          first
      fail ActiveRecord::RecordNotFound if @provider.blank?
    end
end
