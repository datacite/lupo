# frozen_string_literal: true

module ErrorSerializable
  extend ActiveSupport::Concern

  included do
    def serialize_errors(errors, options = {})
      return nil if errors.nil?

      arr = errors.reduce([]) do |sum, err|
          src = err.attribute
          sum << {
            source: err.attribute,
            uid: options[:uid],
            title: err.message,
          }
          sum
        end

      { errors: arr }.to_json
    end
  end
end
