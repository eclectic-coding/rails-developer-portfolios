require 'net/http'
require 'json'

class DeveloperPortfoliosFetcher
  FEED_URL = 'https://raw.githubusercontent.com/emmabostian/developer-portfolios/master/feed.json'

  def self.fetch_and_sync
    new.fetch_and_sync
  end

  def fetch_and_sync
    Rails.logger.info "Fetching developer portfolios from #{FEED_URL}"

    uri = URI(FEED_URL)
    response = Net::HTTP.get_response(uri)

    if response.is_a?(Net::HTTPSuccess)
      data = JSON.parse(response.body)
      sync_portfolios(data)
      Rails.logger.info "Successfully synced #{data.size} developer portfolios"
      true
    else
      Rails.logger.error "Failed to fetch developer portfolios: #{response.code} #{response.message}"
      false
    end
  rescue StandardError => e
    Rails.logger.error "Error fetching developer portfolios: #{e.message}"
    false
  end

  private

  # The source JSON has the shape:
  # [
  #   { "name": "Developer Name", "url": "https://portfolio-url.com", "tagline": "Optional tagline" },
  #   { "name": "Another Developer", "url": "https://another-portfolio.com" }
  # ]
  # We persist `url` into the `path` column.
  def sync_portfolios(data)
    current_paths = data.map { |p| p['url'] }.compact

    # Mark any portfolios that are no longer present in the feed as inactive
    Portfolio.where.not(path: current_paths).update_all(active: false)

    data.each do |portfolio_data|
      url = portfolio_data['url']
      name = portfolio_data['name']
      tagline = portfolio_data['tagline']

      next if url.blank? || name.blank?

      portfolio = Portfolio.find_by(path: url)

      if portfolio
        # Same URL: update name/tagline/active
        portfolio.update!(
          name: name,
          tagline: tagline,
          active: true
        )
        Rails.logger.debug "Updated portfolio: #{portfolio.name}"
      else
        # Possible path change: try to find an inactive record with same name
        old_portfolio = Portfolio.where(active: false, name: name)
                                 .order(updated_at: :desc)
                                 .first

        if old_portfolio
          old_portfolio.update!(
            path: url,
            tagline: tagline,
            active: true
          )
          Rails.logger.info "Updated URL for portfolio: #{old_portfolio.name}"
        else
          Portfolio.create!(
            name: name,
            path: url,
            tagline: tagline,
            active: true
          )
          Rails.logger.info "Created new portfolio: #{name}"
        end
      end
    end
  end
end
