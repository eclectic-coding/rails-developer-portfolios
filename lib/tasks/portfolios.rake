namespace :portfolios do
  desc "Fetch developer portfolios data and sync to the database"
  task fetch: :environment do
    puts "Fetching developer portfolios and syncing to DB..."

    if DeveloperPortfoliosFetcher.fetch_and_sync
      count = Portfolio.count
      active_count = Portfolio.where(active: true).count

      puts "✓ Successfully synced portfolios"
      puts "  Total records:  #{count}"
      puts "  Active records: #{active_count}"

      if active_count.positive?
        sample = Portfolio.active.order(:name).first
        puts "\nSample portfolio:"
        puts "  Name:   #{sample.name}"
        puts "  URL:    #{sample.path}"
        puts "  Tagline: #{sample.tagline.presence || '(none)'}"
      end
    else
      puts "✗ Sync failed. Check logs for details."
    end
  rescue StandardError => e
    puts "✗ Error: #{e.message}"
    puts e.backtrace.first(5)
  end

  desc "Show portfolio stats from the database"
  task show: :environment do
    count = Portfolio.count
    active_count = Portfolio.where(active: true).count

    puts "Portfolios in DB:"
    puts "  Total records:  #{count}"
    puts "  Active records: #{active_count}"

    if active_count.positive?
      puts "\nFirst 5 active portfolios:"
      Portfolio.active.order(:name).limit(5).each_with_index do |portfolio, index|
        puts "#{index + 1}. #{portfolio.name} - #{portfolio.path}"
      end
    else
      puts "No active portfolios found. Try running: rails portfolios:fetch"
    end
  end

  desc "(Deprecated) Clear portfolios cache - no-op now that we use the database"
  task clear_cache: :environment do
    puts "Cache is no longer used. Portfolios are stored in the database."
  end
end
