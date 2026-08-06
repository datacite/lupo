# frozen_string_literal: true

# is_active is stored as binary(1): "\x01" active, "\x00" inactive.
# Ruby truthiness treats "\x00" as truthy, so plain `is_active ? ...` wrongly
# reactivates inactive accounts on every validation.
module BinaryActiveFlag
  extend ActiveSupport::Concern

  private
    def normalize_binary_is_active
      self.is_active = binary_is_active? ? "\x01" : "\x00"
    end

    # Accepts API booleans/integers and the binary column values used in the DB.
    def binary_is_active?(value = is_active)
      case value
      when true, 1, "1"
        true
      when false, 0, "0", nil
        false
      else
        str = value.to_s
        return false if str.empty?

        str.getbyte(0) == 1
      end
    end
end
