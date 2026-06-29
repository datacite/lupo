# frozen_string_literal: true

module RequestHelper
  LEGACY_SUNSET_HTTP_DATE = Time.utc(2026, 7, 1).httpdate.freeze
  LEGACY_SUNSET_LINK_FRAGMENT =
    "datacite-rest-api-legacy-endpoints-deprecation"

  # Parse JSON response to ruby hash
  def json
    JSON.parse(last_response.body)
  end

  def expect_legacy_sunset_headers
    expect(last_response.headers["Sunset"]).to eq(LEGACY_SUNSET_HTTP_DATE)
    expect(last_response.headers["Link"]).to include('rel="sunset"')
    expect(last_response.headers["Link"]).to include(LEGACY_SUNSET_LINK_FRAGMENT)
  end

  def expect_no_legacy_sunset_header
    expect(last_response.headers["Sunset"]).to be_nil
  end
end
