class ResolutionReportsController < ApplicationController
  before_action :set_resolution_report, only: %i[show update destroy]

  def index
    # page = page_from_params(params)

    direction = params[:sort] == "asc" ? :asc : :desc
    reports = ResolutionReport.order(period: direction, prefix: :asc)

    render json: ResolutionReportSerializer.new(reports).serializable_hash
  end

  def show
    render json: ResolutionReportSerializer.new(@resolution_report).serializable_hash
  end

  def create
    report = ResolutionReport.new(resolution_report_params)

    if report.save
      render json: ResolutionReportSerializer.new(report).serializable_hash, status: :created
    else
      render json: { errors: report.errors }, status: :unprocessable_entity
    end
  end

  def update
    if @resolution_report.update(resolution_report_params)
      render json: ResolutionReportSerializer.new(@resolution_report).serializable_hash
    else
      render json: { errors: @resolution_report.errors }, status: :unprocessable_entity
    end
  end

  def destroy
    @resolution_report.destroy!
    head :no_content
  end

  private
    def set_resolution_report
      @resolution_report = ResolutionReport.find(params.require(:id))
    end

    def resolution_report_params
      params.expect(resolution_report: [
        :period,
        :prefix,
        :total_attempted_resolutions,
        :successful_resolutions,
        :failed_resolutions,
        :total_unique_dois,
        :unique_doi_successes,
        :unique_doi_failures,
      ])
    end
end
