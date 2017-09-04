class DatasetsController < ApplicationController
  before_action :set_dataset, only: [:show, :update, :destroy]
  before_action :authenticate_user_from_token!
  load_and_authorize_resource :except => [:index, :show]

  # # # GET /datasets
  def index

    # response = Dataset.get_all(params)
    # page = (params.dig(:page, :number) || 1).to_i
    # per_page =(params.dig(:page, :size) || 25).to_i
    # total = response[:response].size
    # total_pages = (total.to_f / per_page).ceil
    # collection = response[:response].page(page).per(per_page).order(created: :desc).to_a
    #
    # collection.each do |line|
    #   dc = Client.find(line[:datacentre])
    #   line[:client_id] = dc.uid.downcase
    #   line[:client_name] = dc.name
    # end
    #
    #
    # clients = nil
    # clients = collection.map{|doi| { id: doi[:id],  client_id: doi[:client_id],  name: doi[:client_name] }}.group_by { |d| d[:client_id] }.map{ |k, v| { id: k, title: v.first[:name], count: v.count} }
    #
    #
    # meta = { total: total,
    #          total_pages: total_pages,
    #          page: page,
    #          clients: clients,
    #          years: response[:years]
    #         }
    #
    # render jsonapi: @dois[:data], meta: @dois[:meta], include: @include
  end
  #
  # # # GET /datasets/1
  def show
    render jsonapi: @dataset
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
      attributes = [:uid, :created, :doi, :is_active, :version, :client_id, :url]
      params.require(:data).permit(:id, :type, attributes: attributes)
    end
  #   # Only allow a trusted parameter "white list" through.
  # def dataset_params
  #   params.require(:data)
  #     .require(:attributes)
  #     .permit(:created, :doi, :is_active, :is_ref_quality, :last_landing_page_status, :last_landing_page_status_check, :last_landing_page_status_check, :updated, :version, :client_id, :minted)
  #
  #   ds_params= ActiveModelSerializers::Deserialization.jsonapi_parse(params).transform_keys!{ |key| key.to_s.snakecase }
  #
  #   datacentre = Client.find_by(symbol: ds_params["client_id"])
  #   fail("client_id Not found") unless   datacentre.present?
  #   ds_params["datacentre"] = datacentre.id
  #   ds_params
  # end
end
