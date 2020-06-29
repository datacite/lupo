class IndexController < ApplicationController
  include ActionController::MimeResponds

  prepend_before_action :authenticate_user!
  before_action :set_doi, only: [:show]
  
  def index
    render plain: ENV['SITE_TITLE']
  end

  def routing_error
    fail ActiveRecord::RecordNotFound
  end

  def method_not_allowed
    response.set_header('Allow', 'POST')
    render json: { "message": "This endpoint only supports POST requests." }.to_json, status: :method_not_allowed
  end
end
