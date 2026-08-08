class Rack::Attack
  # Reuse the app's cache store instead of an in-process store, so limits are
  # shared across all Puma workers/processes.
  Rack::Attack.cache.store = Rails.cache

  # Throttle all requests by IP: 300 requests per 5 minutes.
  throttle("req/ip", limit: 300, period: 5.minutes) do |req|
    req.ip unless req.path == "/up"
  end
end

Rack::Attack.throttled_responder = lambda do |_request|
  [429, { "Content-Type" => "text/plain" }, ["Too many requests. Please try again later.\n"]]
end