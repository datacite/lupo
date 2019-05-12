# frozen_string_literal: true

class LupoSchema < GraphQL::Schema
  default_max_page_size 250
  max_depth 10

  # mutation(Types::MutationType)
  query(QueryType)
end

GraphQL::Errors.configure(LupoSchema) do
  rescue_from ActiveRecord::RecordNotFound do |exception|
    GraphQL::ExecutionError.new("Record not found")
  end

  rescue_from ActiveRecord::RecordInvalid do |exception|
    GraphQL::ExecutionError.new(exception.record.errors.full_messages.join("\n"))
  end

  # rescue_from StandardError do |exception|
  #   GraphQL::ExecutionError.new("Please try to execute the query for this field later")
  # end

  # rescue_from CustomError do |exception, object, arguments, context|
  #   nil
  # end
end
