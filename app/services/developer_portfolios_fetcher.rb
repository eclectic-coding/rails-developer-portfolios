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

      # Bump a version key used for fragment caching of portfolios views.
      Rails.cache.increment('portfolios_version') || Rails.cache.write('portfolios_version', 1)

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

  # Feed shape: [{ "name": "...", "url": "https://...", "tagline": "..." }, ...]
  # We persist `url` into the `path` column.
  def sync_portfolios(data)
    current_paths = data.map { |entry| entry['url'] }.compact
    deactivate_removed(current_paths)

    # Preload after deactivation so inactive_by_name captures portfolios just
    # deactivated above, enabling correct rename detection within the same sync.
    by_path          = Portfolio.all.index_by(&:path)
    inactive_by_name = Portfolio.where(active: false)
                                .order(updated_at: :desc)
                                .each_with_object({}) { |record, memo| memo[record.name] ||= record }

    data.each do |entry|
      next if entry['url'].blank? || entry['name'].blank?

      upsert_entry(entry, by_path, inactive_by_name)
    end
  end

  def deactivate_removed(current_paths)
    Portfolio.where.not(path: current_paths).find_each do |portfolio|
      portfolio.update_columns(active: false)
      portfolio.site_screenshot.purge if portfolio.site_screenshot.attached?
    end
  end

  def upsert_entry(entry, by_path, inactive_by_name)
    url     = entry['url']
    name    = entry['name']
    tagline = entry['tagline']

    if (portfolio = by_path[url])
      portfolio.update!(name: name, tagline: tagline, active: true)
      Rails.logger.debug "Updated portfolio: #{portfolio.name}"
    elsif (old_portfolio = inactive_by_name[name])
      old_portfolio.update!(path: url, tagline: tagline, active: true)
      Rails.logger.info "Updated URL for portfolio: #{old_portfolio.name}"
    else
      Portfolio.create!(name: name, path: url, tagline: tagline, active: true)
      Rails.logger.info "Created new portfolio: #{name}"
    end
  end
end
