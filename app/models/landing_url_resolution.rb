# frozen_string_literal: true

# Domain outcome for DOI landing-URL resolution (stored attribute vs Handle).
# Controllers map these to REST JSON or MDS plain-text; they do not re-encode policy.
class LandingUrlResolution
  attr_reader :kind, :url, :status, :body

  KINDS = %i[ok no_content forbidden_handle upstream].freeze

  def initialize(kind, url: nil, status: nil, body: nil)
    @kind = kind.to_sym
    fail ArgumentError, "unknown kind #{kind.inspect}" unless KINDS.include?(@kind)

    @url = url
    @status = status
    @body = body
  end

  def self.ok(url)
    new(:ok, url: url)
  end

  def self.no_content
    new(:no_content)
  end

  def self.forbidden_handle
    new(:forbidden_handle)
  end

  def self.upstream(status:, body:)
    new(:upstream, status: status, body: body)
  end

  def ok?
    kind == :ok
  end

  def no_content?
    kind == :no_content
  end

  def forbidden_handle?
    kind == :forbidden_handle
  end

  def upstream?
    kind == :upstream
  end
end
