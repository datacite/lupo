# frozen_string_literal: true

module RequestHelper
  # Parse JSON response to ruby hash
  def json
    JSON.parse(last_response.body)
  end
end
