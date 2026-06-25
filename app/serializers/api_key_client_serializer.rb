# frozen_string_literal: true

class ApiKeyClientSerializer
  include JSONAPI::Serializer

  set_key_transform :camel_lower
  set_type :clients
  set_id :symbol
end
