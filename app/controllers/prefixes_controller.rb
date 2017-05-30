class PrefixesController < JSONAPI::ResourceController
  # before_action :set_prefix, only: [:show, :update, :destroy]
  #
  # # GET /prefixes
  # def index
  #   @prefixes = Prefix.all
  #
  #   render json: @prefixes
  # end
  #
  # # GET /prefixes/1
  # def show
  #   render json: @prefix
  # end
  #
  # # POST /prefixes
  # def create
  #   @prefix = Prefix.new(prefix_params)
  #
  #   if @prefix.save
  #     render json: @prefix, status: :created, location: @prefix
  #   else
  #     render json: @prefix.errors, status: :unprocessable_entity
  #   end
  # end
  #
  # # PATCH/PUT /prefixes/1
  # def update
  #   if @prefix.update(prefix_params)
  #     render json: @prefix
  #   else
  #     render json: @prefix.errors, status: :unprocessable_entity
  #   end
  # end
  #
  # # DELETE /prefixes/1
  # def destroy
  #   @prefix.destroy
  # end
  #
  # private
  #   # Use callbacks to share common setup or constraints between actions.
  #   def set_prefix
  #     @prefix = Prefix.find(params[:id])
  #   end
  #
  #   # Only allow a trusted parameter "white list" through.
  #   def prefix_params
  #     params.require(:prefix).permit(:created, :prefix, :version, :datacentre)
  #   end
end
