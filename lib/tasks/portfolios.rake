namespace :portfolios do
  desc "Fetch and cache developer portfolios data"
  task fetch: :environment do
    puts "Fetching developer portfolios..."
    result = DeveloperPortfoliosFetcher.fetch_and_cache
    puts "✓ Successfully fetched and cached #{result.size} portfolios"

    if result.any?
      puts "\nFirst portfolio:"
      puts "  Name: #{result.first['name']}"
      puts "  Link: #{result.first['link']}"
    end
  rescue StandardError => e
    puts "✗ Error: #{e.message}"
    puts e.backtrace.first(5)
  end

  desc "Clear portfolios cache"
  task clear_cache: :environment do
    puts "Clearing portfolios cache..."
    DeveloperPortfoliosFetcher.clear_cache
    puts "✓ Cache cleared"
  end

  desc "Show cached portfolios data"
  task show: :environment do
    data = DeveloperPortfoliosFetcher.fetch
    if data.any?
      puts "Cached portfolios: #{data.size}"
      puts "\nSample portfolios:"
      data.first(5).each_with_index do |portfolio, index|
        puts "#{index + 1}. #{portfolio['name']} - #{portfolio['link']}"
      end
    else
      puts "No cached data available"
    end
  end
end
