class DatasetsController < ApplicationController
  before_action :set_dataset, only: [:show, :update, :destroy]
  #
  # # # GET /datasets
  def index
    @datasets = Dataset.all

    paginate json: @datasets, include:'datacentres' , per_page: 25
  end
  #
  # # # GET /datasets/1
  def show
    render json: @dataset
  end

  # # POST /datasets
  def create
    pp = dataset_params
    pp[:datacentre] = Datacentre.find(dataset_params[:datacentre])
    @dataset = Dataset.new(pp)

    if @dataset.save
      render json: @dataset, status: :created, location: @dataset
    else
      render json: @dataset.errors, status: :unprocessable_entity
    end
  end
  #
  # # PATCH/PUT /datasets/1
  def update
    pp = dataset_params
    pp[:datacentre] = Datacentre.find(dataset_params[:datacentre])

    if @dataset.update(pp)
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
      # @dataset = Dataset.find(params[:id])
      @dataset = Dataset.find_by(doi: params[:id])
      fail ActiveRecord::RecordNotFound unless @dataset.present?
    end

  #   # Only allow a trusted parameter "white list" through.
  def dataset_params
    params[:data][:attributes] = params[:data][:attributes].transform_keys!{ |key| key.to_s.snakecase }

    params[:data].require(:attributes).permit(:created, :doi, :is_active, :is_ref_quality, :last_landing_page_status, :last_landing_page_status_check, :last_landing_page_status_check, :updated, :version, :datacentre, :minted)
  end
end
