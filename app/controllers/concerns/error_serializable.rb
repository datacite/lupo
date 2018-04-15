module ErrorSerializable
  extend ActiveSupport::Concern

  included do
    def serialize(errors)
      return nil if errors.nil?

      arr = Array.wrap(errors).reduce([]) do |sum, err|
        source = err.keys.first

        Array.wrap(err.values.first).each do |title|
          sum << { source: source, title: title.capitalize }
        end

        sum
      end

      { errors: arr }.to_json
    end
  end
end
