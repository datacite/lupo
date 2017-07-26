class IndexController < ApplicationController
  def index
    render plain: ENV['SITE_TITLE']
  end
end
