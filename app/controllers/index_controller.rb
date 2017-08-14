class IndexController < ApplicationController
  def index
    render plain: ENV['SITE_TITLE']
  end

  def routing_error
    fail ActionController::RoutingError
  end
end
