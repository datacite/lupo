# frozen_string_literal: true

require "securerandom"

class Phrase
  attr_reader :string

  def initialize
    @string = SecureRandom.alphanumeric(16)
  end
end
