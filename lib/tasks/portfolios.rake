namespace :portfolios do
  desc "Fetch developer portfolios data and sync to the database"
  task fetch: :environment do
    puts "Fetching developer portfolios and syncing to DB..."

    if DeveloperPortfoliosFetcher.fetch_and_sync
      # Clear the cached starting letters since portfolios may have changed
      Rails.cache.delete('portfolio_starting_letters')
      puts "✓ Cache cleared"

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

  desc "Clear portfolios cache (starting letters)"
  task clear_cache: :environment do
    Rails.cache.delete('portfolio_starting_letters')
    puts "✓ Portfolio starting letters cache cleared"
  end

  desc "Generate screenshots for portfolios in batches (with delay between batches)"
  task generate_screenshots: :environment do
    batch_size = ENV.fetch("BATCH_SIZE", 10).to_i
    delay_seconds = ENV.fetch("DELAY_SECONDS", 30).to_i

    portfolios = Portfolio.active.to_a
    total = portfolios.count

    puts "Generating screenshots for #{total} active portfolios"
    puts "Batch size: #{batch_size}"
    puts "Delay between batches: #{delay_seconds} seconds"
    puts ""

    portfolios.each_slice(batch_size).with_index do |batch, batch_index|
      batch_number = batch_index + 1
      total_batches = (total.to_f / batch_size).ceil

      puts "Processing batch #{batch_number}/#{total_batches} (#{batch.size} portfolios)..."

      batch.each do |portfolio|
        GeneratePortfolioScreenshotJob.perform_later(portfolio.id)
        print "."
      end

      puts " ✓"

      # Don't delay after the last batch
      if batch_index < total_batches - 1
        puts "Waiting #{delay_seconds} seconds before next batch..."
        sleep delay_seconds
      end
    end

    puts "\n✓ All screenshot jobs queued successfully!"
    puts "Jobs will be processed by Solid Queue in the background."
  end

  desc "Initial setup: fetch portfolios and generate screenshots in batches"
  task setup: :environment do
    puts "=" * 60
    puts "INITIAL SETUP: Fetching portfolios and generating screenshots"
    puts "=" * 60
    puts ""

    # Step 1: Fetch portfolios
    puts "Step 1: Fetching portfolios from upstream..."
    Rake::Task["portfolios:fetch"].invoke
    puts ""

    # Step 2: Generate screenshots
    puts "Step 2: Generating screenshots in batches..."
    Rake::Task["portfolios:generate_screenshots"].invoke
    puts ""

    puts "=" * 60
    puts "SETUP COMPLETE!"
    puts "=" * 60
  end
end
