class RandomController < ApplicationController
  before_action :authenticate_user!
  load_and_authorize_resource Phrase

  def index
    phrase = Phrase.new
    response.headers['X-Consumer-Role'] = current_user && current_user.role_id || 'anonymous'

    render json: { phrase: phrase.string }.to_json
  end
end
