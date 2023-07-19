class DataDumpsController < ApplicationController

  prepend_before_action :authenticate_user!
  # load_and_authorize_resource
  def index
    authorize! :read, :read_data_dumps
    sort =
      case params[:sort]
      when "created"
        { created_at: { order: "asc" } }
      when "-created"
        { created_at: { order: "desc" } }
      when "start"
        { start_date: { order: "asc" } }
      when "-start"
        { start_date: { order: "desc" } }
      when "end"
        { end_date: { order: "asc" } }
      when "-end"
        { end_date: { order: "desc"} }
      else
        { created_at: { order: "desc" } }
      end

    page = page_from_params(params)

    response = DataDump.query(
      "",
      page: page,
      sort: sort
    )

    begin
      total = response.results.total
      total_pages = page[:size].positive? ? (total.to_f / page[:size]).ceil : 0

      data_dumps = response.results

      options = {}
      options[:meta] = {
        total: total,
        "totalPages" => total_pages,
        page: page[:number]
      }.compact

      options[:links] = {
        self: request.original_url,
        next:
          if data_dumps.blank? || page[:number] == total_pages
            nil
          else
            request.base_url + "/data_dumps?" +
              { "page[number]" => page[:number] + 1,
                "page[size]" => page[:size],
                sort: params[:sort],
              }.compact.to_query
          end,
        prev:
          if page[:number] == 1 || page[:number] == 0
            nil
          elsif data_dumps.blank?
            # use the max page size
            request.base_url + "/data_dumps?" +
              { "page[number]" => total_pages,
                "page[size]" => page[:size],
                sort: params[:sort],
              }.compact.to_query
          else
            request.base_url + "/data_dumps?" +
              { "page[number]" => page[:number] - 1,
                "page[size]" => page[:size],
                sort: params[:sort],
              }.compact.to_query
          end
      }.compact

      render json:
               DataDumpSerializer.new(data_dumps, options).serialized_json, status: :ok

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
    authorize! :read, :read_data_dumps
    data_dump = DataDump.where(uid: params[:id]).first
    if data_dump.blank? ||
      (
        data_dump.aasm_state != "complete"
        # TODO: Add conditional check for role here
      )
      fail ActiveRecord::RecordNotFound
    end
    render json: DataDumpSerializer.new(data_dump).serialized_json, status: :ok
  end
end
