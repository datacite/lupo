# frozen_string_literal: true

module ErrorSerializable
  extend ActiveSupport::Concern

  included do
    def serialize_errors(errors, options = {})
      return nil if errors.nil?

      arr =
        Array.wrap(errors.errors).reduce([]) do |sum, err|
          source = err.attribute

          Array.wrap(err.message).each do |title|
            sum <<
              {
                source: source,
                uid: options[:uid],
                title:
                  title.is_a?(String) ? title.sub(/^./, &:upcase) : title.to_s,
              }.compact
          end

          sum
        end

      { errors: arr }.to_json
    end
  end
end
