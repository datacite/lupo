# frozen_string_literal: true

class BaseObject < GraphQL::Schema::Object
  field_class GraphQL::Cache::Field
end
