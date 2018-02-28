class RandomController < ApplicationController
  before_action :authenticate_user!
  load_and_authorize_resource Phrase

  def index
    phrase = Phrase.new

    render json: { phrase: phrase.string }.to_json
  end
end
