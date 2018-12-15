class IndexController < ApplicationController
  include ActionController::MimeResponds

  prepend_before_action :authenticate_user!
  before_action :set_doi, only: [:show]
  
  def index
    render plain: ENV['SITE_TITLE']
  end

  # def routing_error
  #   fail ActionController::RoutingError
  # end
end
