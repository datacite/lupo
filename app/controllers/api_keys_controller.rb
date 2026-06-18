# frozen_string_literal: true

class ApiKeysController < ApplicationController
  before_action :authenticate_user!
  load_and_authorize_resource except: %i[index create]

  def index
    load_client_context

    if @client.nil?
      if current_user&.is_admin_or_staff?
        authorize! :manage, ApiKey
        api_keys = ApiKey.active.order(created_at: :desc)
      else
        raise CanCan::AccessDenied
      end
    else
      authorize! :read, @client
      api_keys = @client.api_keys.active.order(created_at: :desc)
    end

    options = {}
    options[:meta] = { total: api_keys.count }
    options[:params] = { current_ability: current_ability }

    render json: ApiKeySerializer.new(api_keys, options).serializable_hash
  end

  def create
    load_client_context
    raise ActiveRecord::RecordNotFound unless @client

    authorize! :read, @client
    api_key = @client.api_keys.build(safe_params)

    authorize! :create, api_key

    if api_key.save
      options = {
        params: {
          current_ability: current_ability,
          include_plain_key: true,
        },
      }
      render json: ApiKeySerializer.new(api_key, options).serializable_hash,
             status: :created
    else
      render json: {
        errors: api_key.errors.full_messages.map do |m|
          { status: "422", title: m }
        end,
      }, status: :unprocessable_entity
    end
  end

  def destroy
    @api_key.revoke!
    head :no_content
  end

  private
    def load_client_context
      @client = current_user&.client_id.present? ? Client.find_by(symbol: current_user.client_id.upcase) : nil
    end

    def safe_params
      params.require(:data).require(:attributes).permit(:name)
    end
end
