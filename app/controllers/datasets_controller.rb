class DatasetsController < ApplicationController
  before_action :set_dataset, only: [:show, :update, :destroy]
  #
  # # # GET /datasets
  def index
    collection = Dataset
    collection = collection.query(params[:query]) if params[:query]

    if params[:datacentre].present?
      collection = collection.where(datacentre: params[:datacentre])
      @datacentre = collection.where(datacentre: params[:datacentre]).group(:datacentre).count.first
    end

    if params[:datacentre].present?
      datacentres = [{ id: params[:datacentre],
                 datacentre: params[:datacentre],
                 count: Dataset.where(datacentre: params[:datacentre]).count }]
    else
      datacentres = Dataset.where.not(datacentre: nil).order("datacentre DESC").group(:datacentre).count
      datacentres = datacentres.map { |k,v| { id: k.id.to_s, datacentre: k.symbol.to_s, count: v } }
    end
    #
    page = params[:page] || { number: 1, size: 1000 }
    #
    @datasets = Dataset.order(:datacentre).page(page[:number]).per_page(page[:size])
    #
    meta = { total: @datasets.total_entries,
             total_pages: @datasets.total_pages ,
             page: page[:number].to_i,
            #  member_types: member_types,
            #  regions: regions,
             datacentres: datacentres }

    paginate json: @datasets, meta: meta, per_page: 25
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
      # @dataset = Dataset.find(params[:id])
      @dataset = Dataset.find_by(doi: params[:id])
      fail ActiveRecord::RecordNotFound unless @dataset.present?
    end

  #   # Only allow a trusted parameter "white list" through.
  def dataset_params
    params[:data][:attributes] = params[:data][:attributes].transform_keys!{ |key| key.to_s.snakecase }

    ds_params= params[:data].require(:attributes).permit(:created, :doi, :is_active, :is_ref_quality, :last_landing_page_status, :last_landing_page_status_check, :last_landing_page_status_check, :updated, :version, :datacentre, :minted)
    ds_params[:datacentre] = Datacentre.find_by(symbol: ds_params[:datacentre])
    ds_params
  end
end
