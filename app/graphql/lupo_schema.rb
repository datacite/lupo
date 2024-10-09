# frozen_string_literal: true

class LupoSchema < GraphQL::Schema
  include ApolloFederation::Schema

  use GraphQL::Pagination::Connections
  # custom connection wrapper for Elasticsearch
  connections.add(
    Elasticsearch::Model::Response::Response,
    ElasticsearchModelResponseConnection,
  )

  # custom connection wrapper for external REST APIs
  connections.add(Hash, HashConnection)

  # use GraphQL::Tracing::DataDogTracing, service: "graphql"
  use ApolloFederation::Tracing
  use GraphQL::Batch
  use GraphQL::Cache

  default_max_page_size 1_000
  max_depth 10

  mutation(MutationType)
  query(QueryType)
end

GraphQL::Errors.configure(LupoSchema) do
  rescue_from ActiveRecord::RecordNotFound do |_exception|
    GraphQL::ExecutionError.new("Record not found")
  end

  rescue_from ActiveRecord::RecordInvalid do |exception|
    GraphQL::ExecutionError.new(
      exception.record.errors.full_messages.join("\n"),
    )
  end

  rescue_from CSL::ParseError do |exception|
    Raven.capture_exception(exception)
    message = exception.message
    GraphQL::ExecutionError.new(message)
  end

  rescue_from StandardError do |exception|
    Raven.capture_exception(exception)
    message =
      if Rails.env.production?
        "We are sorry, but an error has occured. This problem has been logged and support has been notified. Please try again later. If the error persists please contact support."
      else
        exception.message
      end
    GraphQL::ExecutionError.new(message)
  end
end
