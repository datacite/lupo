# frozen_string_literal: true

module Mds
  # Simple result object for MDS operations (status + body/message + optional headers).
  class Result
    attr_reader :status, :body, :headers, :error

    def initialize(status:, body: nil, headers: {}, error: nil)
      @status = status
      @body = body
      @headers = headers
      @error = error
    end

    def success?
      status.to_i.between?(200, 299)
    end

    def self.ok(body = "OK", status: 200, headers: {})
      new(status: status, body: body, headers: headers)
    end

    def self.created(body = "OK", headers: {})
      new(status: 201, body: body, headers: headers)
    end

    def self.no_content
      new(status: 204, body: nil)
    end

    def self.error(status, message)
      new(status: status, body: message, error: message)
    end
  end
end
