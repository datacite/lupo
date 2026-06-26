# frozen_string_literal: true

class ApiKeysController < ApplicationController
  before_action :authenticate_user!
  before_action :reject_api_key_credentials!

  load_and_authorize_resource except: %i[index create]

  def index
    load_client_context

    include_revoked = params[:include_revoked] == "true"

    if @client.nil?
      if current_user&.is_admin_or_staff?
        authorize! :manage, ApiKey
        api_keys = include_revoked ? ApiKey.all : ApiKey.active
      else
        raise CanCan::AccessDenied
      end
    else
      if include_revoked && !current_user&.is_admin_or_staff?
        raise CanCan::AccessDenied
      end
      authorize_api_key_index!(@client)
      api_keys = include_revoked ? @client.api_keys : @client.api_keys.active
    end

    api_keys = order_api_keys(api_keys, include_revoked)

    options = {
      meta: { total: api_keys.count },
      params: { current_ability: current_ability },
    }

    render json: ApiKeySerializer.new(api_keys, options).serializable_hash
  end

  def create
    load_client_context
    raise ActiveRecord::RecordNotFound unless @client

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
    def reject_api_key_credentials!
      return unless current_user&.api_key_authenticated?

      raise CanCan::AccessDenied,
            "API keys cannot manage credentials; use the client password."
    end

    def authorize_api_key_index!(client)
      probe = client.api_keys.build
      unless can?(:manage, probe) || can?(:read, probe)
        raise CanCan::AccessDenied
      end
    end

    def load_client_context
      @client = current_user&.client_id.present? ? Client.find_by(symbol: current_user.client_id.upcase) : nil
    end

    def order_api_keys(scope, include_revoked)
      if include_revoked
        scope.order(
          Arel.sql("revoked_at IS NULL DESC, revoked_at DESC, created_at DESC"),
        )
      else
        scope.order(created_at: :desc)
      end
    end

    def safe_params
      params.require(:data).require(:attributes).permit(:name)
    end
end
