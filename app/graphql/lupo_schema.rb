# frozen_string_literal: true

class LupoSchema < GraphQL::Schema
  include ApolloFederation::Schema

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
  use GraphQL::FragmentCache

  default_max_page_size 1_000
  max_depth 10

  mutation(MutationType)
  query(QueryType)

  rescue_from ActiveRecord::RecordNotFound do |_exception|
    raise GraphQL::ExecutionError, "Record not found"
  end

  rescue_from ActiveRecord::RecordInvalid do |exception|
    raise GraphQL::ExecutionError,
      exception.record.errors.full_messages.join("\n")
  end

  rescue_from CSL::ParseError do |exception|
    Sentry.capture_exception(exception)
    message = exception.message
    raise GraphQL::ExecutionError, message
  end

  rescue_from StandardError do |exception|
    Sentry.capture_exception(exception)
    message =
      if Rails.env.production?
        "We are sorry, but an error has occured. This problem has been logged and support has been notified. Please try again later. If the error persists please contact support."
      else
        exception.message
      end
    raise GraphQL::ExecutionError, message
  end
end
