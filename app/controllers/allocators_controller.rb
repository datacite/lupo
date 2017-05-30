class AllocatorsController < JSONAPI::ResourceController
  # before_action :set_allocator, only: [:show, :update, :destroy]
  #
  # # GET /allocators
  # def index
  #   @allocators = Allocator.all
  #
  #   render json: @allocators
  # end
  #
  # # GET /allocators/1
  # def show
  #   render json: @allocator
  # end
  #
  # # POST /allocators
  # def create
  #   @allocator = Allocator.new(allocator_params)
  #
  #   if @allocator.save
  #     render json: @allocator, status: :created, location: @allocator
  #   else
  #     render json: @allocator.errors, status: :unprocessable_entity
  #   end
  # end
  #
  # # PATCH/PUT /allocators/1
  # def update
  #   if @allocator.update(allocator_params)
  #     render json: @allocator
  #   else
  #     render json: @allocator.errors, status: :unprocessable_entity
  #   end
  # end
  #
  # # DELETE /allocators/1
  # def destroy
  #   @allocator.destroy
  # end
  #
  # private
  #   # Use callbacks to share common setup or constraints between actions.
  #   def set_allocator
  #     @allocator = Allocator.find(params[:id])
  #   end
  #
  #   # Only allow a trusted parameter "white list" through.
  #   def allocator_params
  #     params.require(:allocator).permit(:comments, :contact_email, :contact_name, :created, :doi_quota_allowed, :doi_quota_used, :is_active, :name, :password, :role_name, :symbol, :updated, :version, :experiments)
  #   end
end
