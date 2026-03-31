module RequestHelpers
  def auth_headers(user)
    { "Authorization" => "Bearer #{user.api_token}" }
  end

  def json_response
    JSON.parse(response.body, symbolize_names: true)
  end
end
