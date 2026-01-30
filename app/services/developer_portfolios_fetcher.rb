require 'net/http'
require 'json'

class DeveloperPortfoliosFetcher
  CACHE_KEY = 'developer_portfolios_data'
  CACHE_EXPIRY = 1.day
  FEED_URL = 'https://raw.githubusercontent.com/emmabostian/developer-portfolios/master/feed.json'

  def self.fetch
    new.fetch
  end

  def self.fetch_and_cache
    new.fetch_and_cache
  end

  def fetch
    # Try to get cached data first
    cached_data = Rails.cache.read(CACHE_KEY)
    return cached_data if cached_data.present?

    # If no cache, fetch fresh data
    fetch_and_cache
  end

  def fetch_and_cache
    Rails.logger.info "Fetching developer portfolios from #{FEED_URL}"

    uri = URI(FEED_URL)
    response = Net::HTTP.get_response(uri)

    if response.is_a?(Net::HTTPSuccess)
      data = JSON.parse(response.body)
      Rails.cache.write(CACHE_KEY, data, expires_in: CACHE_EXPIRY)
      Rails.logger.info "Successfully cached #{data.size} developer portfolios"
      data
    else
      Rails.logger.error "Failed to fetch developer portfolios: #{response.code} #{response.message}"
      # Return empty array if fetch fails and no cached data exists
      []
    end
  rescue StandardError => e
    Rails.logger.error "Error fetching developer portfolios: #{e.message}"
    # Try to return stale cache if available
    Rails.cache.read(CACHE_KEY) || []
  end

  def self.clear_cache
    Rails.cache.delete(CACHE_KEY)
  end
end
