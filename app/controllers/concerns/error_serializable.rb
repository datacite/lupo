# frozen_string_literal: true

module ErrorSerializable
  extend ActiveSupport::Concern

  included do
    def serialize_errors(errors, options = {})
      return nil if errors.nil?

      errors_arr = errors
        .map { |err| {
            source: err.attribute,
            title: err.message.sub(/^./, &:upcase),
            uid: options[:uid]
          }.compact
        }.uniq

      { errors: errors_arr }.to_json
    end
  end
end
