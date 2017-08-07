class DatasetsController < ApplicationController
  before_action :set_dataset, only: [:show, :update, :destroy]
  #
  # # # GET /datasets
  def index
    collection = Dataset
    collection = collection.query(params[:query]) if params[:query]

    if params[:datacenter].present?
      collection = collection.where(datacentre: params[:datacenter])
      @datacenter = collection.where(datacentre: params[:datacenter]).group(:datacenter).count.first
    end

    if params[:datacenter].present?
      datacenters = [{ id: params[:datacenter],
                 datacenter: params[:datacenter],
                 count: Dataset.where(datacentre: params[:datacenter]).count }]
    else
      datacenters = Dataset.where.not(datacentre: nil).order("datacentre DESC").group(:datacentre).count
      datacenters = datacenters.map { |k,v| { id: k.to_s, datacenter: k.to_s, count: v } }
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
             datacenters: datacenters }

    paginate json: @datasets, meta: meta, per_page: 25
  end
  #
  # # # GET /datasets/1
  def show
    render json: @dataset, include:['datacentre']
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

    ds_params= params[:data].require(:attributes).permit(:created, :doi, :is_active, :is_ref_quality, :last_landing_page_status, :last_landing_page_status_check, :last_landing_page_status_check, :updated, :version, :datacenter_id, :minted)
    ds_params[:datacentre] = Datacenter.find_by(symbol: ds_params[:datacenter_id]).id
    ds_params
  end
end
