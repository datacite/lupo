# frozen_string_literal: true

class LupoSchema < GraphQL::Schema
  include ApolloFederation::Schema

  use GraphQL::Tracing::DataDogTracing, service: 'graphql'
  use ApolloFederation::Tracing

  default_max_page_size 1000
  max_depth 10

  # mutation(Types::MutationType)
  query(Types::QueryType)

  use GraphQL::Batch
  use GraphQL::Cache
end

GraphQL::Errors.configure(LupoSchema) do
  rescue_from ActiveRecord::RecordNotFound do |exception|
    GraphQL::ExecutionError.new("Record not found")
  end

  rescue_from ActiveRecord::RecordInvalid do |exception|
    GraphQL::ExecutionError.new(exception.record.errors.full_messages.join("\n"))
  end

  rescue_from StandardError do |exception|
    Raven.capture_exception(exception)
    message = Rails.env.production? ? "We are sorry, but an error has occured. This problem has been logged and support has been notified. Please try again later. If the error persists please contact support." : exception.message
    GraphQL::ExecutionError.new(message)
  end

  # rescue_from CustomError do |exception, object, arguments, context|
  #   nil
  # end
end
