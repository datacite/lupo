class StatusController < ApplicationController
  def index
    status = Status.new
    render json: status
  end
end
