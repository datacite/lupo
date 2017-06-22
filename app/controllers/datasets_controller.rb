class DatasetsController < ApplicationController
  # before_action :set_dataset, only: [:show, :update, :destroy]
  #
  # # # GET /datasets
  def index
    # @datasets = Dataset.page(params[:page] ? params[:page][:number] : 1)
    # @datasets = Dataset.all
    @datasets = Dataset.find_by(id: 5)

    render json: @datasets
  end
  #
  # # # GET /datasets/1
  def show
    render json: @dataset
  end

  # # POST /datasets
  def create
    @dataset = Dataset.new(dataset_params)

    if @dataset.save
      render json: @dataset, status: :created, location: @dataset
    else
      render json: @dataset.errors, status: :unprocessable_entity
    end
  end
  #
  # # PATCH/PUT /datasets/1
  def update
    if @dataset.update(dataset_params)
      render json: @dataset
    else
      render json: @dataset.errors, status: :unprocessable_entity
    end
  end

  # DELETE /datasets/1
  def destroy
    @dataset.destroy
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_dataset
      @dataset = Dataset.find(params[:id])
    end

  #   # Only allow a trusted parameter "white list" through.
  def dataset_params
    params.require(:dataset).permit(:created, :doi, :is_active, :is_ref_quality, :last_landing_page_status, :last_landing_page_status_check, :last_landing_page_status_check, :updated, :version, :datacentre, :minted)
  end
end
