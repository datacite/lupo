module ErrorSerializable
  extend ActiveSupport::Concern

  included do
    def serialize(errors)
      return if errors.nil?

      json = {}
      new_hash = errors.to_hash(true).map do |k, v|
        v.map do |msg|
          { source: k, title: msg }
        end
      end.flatten
      json[:errors] = new_hash
      json
    end
  end
end
