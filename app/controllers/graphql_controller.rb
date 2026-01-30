# frozen_string_literal: true

class GraphqlController < ApplicationController
  before_action :authenticate_user!

  def execute
    variables = ensure_hash(params[:variables])
    query = params[:query]
    operation_name = params[:operationName]
    context = {
      tracing_enabled: ApolloFederation::Tracing.should_add_traces(headers),
      current_user: current_user,
    }
    result =
      LupoSchema.execute(
        query,
        variables: variables,
        context: context,
        operation_name: operation_name,
      )
    render json: result
  rescue StandardError => e
    raise e unless Rails.env.development?

    handle_error_in_development e
  end

  private
    # Handle form data, JSON body, or a blank value
    def ensure_hash(ambiguous_param)
      case ambiguous_param
      when String
        ambiguous_param.present? ? ensure_hash(JSON.parse(ambiguous_param)) : {}
      when Hash, ActionController::Parameters
        ambiguous_param
      when nil
        {}
      else
        raise ArgumentError, "Unexpected parameter: #{ambiguous_param}"
      end
    end

    def handle_error_in_development(e)
      Rails.logger.error e.message
      Rails.logger.error e.backtrace.join("\n")

      render json: {
        error: { message: e.message, backtrace: e.backtrace }, data: {}
      },
             status: :internal_server_error
    end
end
