module RequestHelper
  # Parse JSON response to ruby hash
  def json
    JSON.parse(last_response.body)
  end
end
