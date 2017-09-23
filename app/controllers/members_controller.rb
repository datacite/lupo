class MembersController < ApplicationController
  def index
    @members = Member.where(params)
    render jsonapi: @members[:data], meta: @members[:meta]
  end

  def show
    @member = Member.where(id: params[:id])
    fail AbstractController::ActionNotFound unless @member.present?

    render jsonapi: @member[:data]
  end
end
