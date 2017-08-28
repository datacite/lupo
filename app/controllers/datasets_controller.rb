class DatasetsController < ApplicationController
  before_action :set_dataset, only: [:show, :update, :destroy]
  before_action :authenticate_user_from_token!
  load_and_authorize_resource :except => [:index, :show]

  serialization_scope :view_context


  # # # GET /datasets
  def index
    options = { }
    params[:query] ||= "*"
    response = Dataset.search(params[:query], options)


    # pagination
    page = (params.dig(:page, :number) || 1).to_i
    per_page =(params.dig(:page, :size) || 25).to_i
    total = response[:response].size
    total_pages = (total.to_f / per_page).ceil
    collection = response[:response].page(page).per(per_page).order(created: :desc).to_a

    years = nil
    years = collection.map{|doi| { id: doi[:id],  year: doi[:created].year }}.group_by { |d| d[:year] }.map{ |k, v| { id: k, title: k, count: v.count} }
    clients = nil
    clients = collection.map{|doi| { id: doi[:id],  datacenter_id: doi[:datacenter_id] }}.group_by { |d| d[:datacenter_id] }.map{ |k, v| { id: k, title: k, count: v.count} }


    meta = { total: total,
             total_pages: total_pages,
             page: page,
             clients: clients,
             years: years
            }

    render jsonapi: collection, meta: meta
  end
  #
  # # # GET /datasets/1
  def show
    render jsonapi: @dataset, include:['datacentre']
  end

  # # POST /datasets
  def create
    unless [:type, :attributes].all? { |k| safe_params.key? k }
      render json: { errors: [{ status: 422, title: "Missing attribute: type."}] }, status: :unprocessable_entity
    else
      @dataset = Dataset.new(safe_params.except(:type))
      authorize! :create, @dataset

      if @dataset.save
        render json: @dataset, status: :created, location: @dataset
      else
        render json: serialize(@dataset.errors), status: :unprocessable_entity
      end
    end
  end
  #
  # # PATCH/PUT /datasets/1
  def update
    unless [:type, :attributes].all? { |k| safe_params.key? k }
      render json: { errors: [{ status: 422, title: "Missing attribute: type."}] }, status: :unprocessable_entity
    else
      if @dataset.update_attributes(safe_params.except(:type))
        render json: @dataset
      else
        render json: serialize(@dataset.errors), status: :unprocessable_entity
      end
    end
  end

  # DELETE /datasets/1
  def destroy
    @dataset.destroy
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_dataset
      @dataset = Dataset.where(doi: params[:id]).first
      fail ActiveRecord::RecordNotFound unless @dataset.present?
    end


  private

  # Only allow a trusted parameter "white list" through.
  def safe_params
    attributes = [:uid, :created, :doi, :is_active, :version, :datacenter_id]
    params.require(:data).permit(:id, :type, attributes: attributes)
  end
  #   # Only allow a trusted parameter "white list" through.
  # def dataset_params
  #   params.require(:data)
  #     .require(:attributes)
  #     .permit(:created, :doi, :is_active, :is_ref_quality, :last_landing_page_status, :last_landing_page_status_check, :last_landing_page_status_check, :updated, :version, :datacenter_id, :minted)
  #
  #   ds_params= ActiveModelSerializers::Deserialization.jsonapi_parse(params).transform_keys!{ |key| key.to_s.snakecase }
  #
  #   datacentre = Datacenter.find_by(symbol: ds_params["datacenter_id"])
  #   fail("datacenter_id Not found") unless   datacentre.present?
  #   ds_params["datacentre"] = datacentre.id
  #   ds_params
  # end
end
