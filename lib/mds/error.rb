# frozen_string_literal: true

module Mds
  # Protocol-level error for the embedded MDS surface.
  # Controllers raise this; ApplicationController maps status + plain-text body.
  class Error < StandardError
    attr_reader :status

    def initialize(message, status:)
      super(message)
      @status = status.to_i
    end
  end
end
