# frozen_string_literal: true

module ErrorSerializable
  extend ActiveSupport::Concern

  included do
    # the previous serialization method only returned the first error
    # this implementation returns all
    # this way the consumer can know everything that is wrong and not get information in a piecemeal manner
    def serialize_errors(errors, options = {})
      return nil if errors.nil?

      errors_arr = []

      errors.each do |err|
        unless errors_arr.any? { |e| e[:source] == err.attribute }
          new_err = { source: err.attribute, title: capitalize_error_message(err) }
          new_err[:uid] = options[:uid] if options[:uid].present?
          errors_arr << new_err
        end
      end

      { errors: errors_arr }.to_json
    end
  end

  private
    def capitalize_error_message(error)
      error.message.sub(/^./, &:upcase)
    end
end
