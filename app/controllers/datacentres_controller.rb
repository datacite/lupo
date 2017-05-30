# class datacentresController < ApplicationController
class DatacentresController < JSONAPI::ResourceController
  # before_action :set_datacentre, only: [:show, :update, :destroy]

  # # GET /datacentres
  # def index
  #   @datacentres = datacentre.all
  #
  #   render json: @datacentres
  # end
  #
  # # GET /datacentres/1
  # def show
  #   render json: @datacentre
  # end
  #
  # # POST /datacentres
  # def create
  #   @datacentre = datacentre.new(datacentre_params)
  #
  #   if @datacentre.save
  #     render json: @datacentre, status: :created, location: @datacentre
  #   else
  #     render json: @datacentre.errors, status: :unprocessable_entity
  #   end
  # end
  #
  # # PATCH/PUT /datacentres/1
  # def update
  #   if @datacentre.update(datacentre_params)
  #     render json: @datacentre
  #   else
  #     render json: @datacentre.errors, status: :unprocessable_entity
  #   end
  # end
  #
  # # DELETE /datacentres/1
  # def destroy
  #   @datacentre.destroy
  # end
  #
  # private
  #   # Use callbacks to share common setup or constraints between actions.
  #   def set_datacentre
  #     @datacentre = datacentre.find(params[:id])
  #   end
  #
  #   # Only allow a trusted parameter "white list" through.
  #   def datacentre_params
  #     params.require(:datacentre).permit(:comments, :contact_email, :contact_name, :created, :doi_quota_allowed, :doi_quota_used, :domains, :is_active, :name, :password, :role_name, :symbol, :updated, :version, :allocator, :experiments)
  #   end
end
