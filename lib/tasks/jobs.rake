namespace :jobs do
  desc "Show status of Solid Queue jobs"
  task status: :environment do
    puts "=" * 60
    puts "SOLID QUEUE JOB STATUS"
    puts "=" * 60
    puts ""

    # Check pending jobs
    pending = SolidQueue::Job.where(finished_at: nil).count
    failed = SolidQueue::FailedExecution.count
    total = SolidQueue::Job.count

    puts "Overall Status:"
    puts "  Total jobs:    #{total}"
    puts "  Pending:       #{pending}"
    puts "  Failed:        #{failed}"
    puts "  Completed:     #{total - pending}"
    puts ""

    # Check screenshot jobs specifically
    screenshot_jobs = SolidQueue::Job.where("class_name = ?", "GeneratePortfolioScreenshotJob")
    screenshot_pending = screenshot_jobs.where(finished_at: nil).count
    screenshot_total = screenshot_jobs.count

    puts "Screenshot Jobs:"
    puts "  Total:         #{screenshot_total}"
    puts "  Pending:       #{screenshot_pending}"
    puts "  Completed:     #{screenshot_total - screenshot_pending}"
    puts ""

    if screenshot_pending > 0
      puts "Recent Pending Screenshot Jobs:"
      SolidQueue::Job.where("class_name = ?", "GeneratePortfolioScreenshotJob")
                     .where(finished_at: nil)
                     .order(created_at: :desc)
                     .limit(10)
                     .each do |job|
        puts "  ID: #{job.id} | Created: #{job.created_at} | Priority: #{job.priority}"
      end
      puts ""
    end

    if failed > 0
      puts "Failed Jobs:"
      SolidQueue::FailedExecution.order(created_at: :desc).limit(10).each do |failure|
        puts "  Job: #{failure.job.class_name} | Error: #{failure.error.message.truncate(80)}"
        puts "  Time: #{failure.created_at}"
        puts "  ---"
      end
    end
  end

  desc "Show failed jobs with full details"
  task failed: :environment do
    puts "=" * 60
    puts "FAILED JOBS"
    puts "=" * 60
    puts ""

    failures = SolidQueue::FailedExecution.order(created_at: :desc).limit(20)

    if failures.empty?
      puts "✓ No failed jobs!"
    else
      failures.each_with_index do |failure, index|
        puts "#{index + 1}. #{failure.job.class_name}"
        puts "   Job ID: #{failure.job_id}"
        puts "   Failed at: #{failure.created_at}"
        puts "   Error: #{failure.error.message}"
        puts "   Backtrace:"
        failure.error.backtrace&.first(3)&.each do |line|
          puts "     #{line}"
        end
        puts ""
      end
    end
  end

  desc "Check if workers are running"
  task workers: :environment do
    puts "=" * 60
    puts "SOLID QUEUE WORKERS"
    puts "=" * 60
    puts ""

    # Check for active processes
    processes = SolidQueue::Process.where("last_heartbeat_at > ?", 5.minutes.ago)

    if processes.any?
      puts "✓ Active workers found: #{processes.count}"
      processes.each do |process|
        puts "  PID: #{process.hostname}:#{process.process_id}"
        puts "  Last heartbeat: #{process.last_heartbeat_at}"
        puts "  Kind: #{process.kind}"
        puts ""
      end
    else
      puts "✗ No active workers found!"
      puts ""
      puts "This means your Solid Queue workers are not running."
      puts "On Hatchbox, check:"
      puts "  1. Is your Procfile configured correctly?"
      puts "  2. Are background workers enabled in Hatchbox?"
      puts "  3. Check your deployment logs"
    end
  end

  desc "Check portfolios without screenshots"
  task missing_screenshots: :environment do
    puts "=" * 60
    puts "PORTFOLIOS WITHOUT SCREENSHOTS"
    puts "=" * 60
    puts ""

    portfolios_without_screenshots = Portfolio.active.select { |p| !p.site_screenshot.attached? }
    total_active = Portfolio.active.count

    puts "Active portfolios: #{total_active}"
    puts "Without screenshots: #{portfolios_without_screenshots.count}"
    puts ""

    if portfolios_without_screenshots.any?
      puts "Sample (first 10):"
      portfolios_without_screenshots.first(10).each do |portfolio|
        puts "  #{portfolio.name} (ID: #{portfolio.id})"
      end
    else
      puts "✓ All active portfolios have screenshots!"
    end
  end

  desc "Full diagnostic report"
  task diagnostic: :environment do
    puts "\n" + "=" * 60
    puts "SOLID QUEUE DIAGNOSTIC REPORT"
    puts "=" * 60

    puts "\n1. WORKERS STATUS"
    puts "-" * 60
    Rake::Task["jobs:workers"].execute

    puts "\n2. JOBS STATUS"
    puts "-" * 60
    Rake::Task["jobs:status"].execute

    puts "\n3. PORTFOLIOS STATUS"
    puts "-" * 60
    total = Portfolio.active.count
    with_screenshots = Portfolio.active.select { |p| p.site_screenshot.attached? }.count
    puts "Active portfolios: #{total}"
    puts "With screenshots: #{with_screenshots}"
    puts "Missing screenshots: #{total - with_screenshots}"

    puts "\n" + "=" * 60
    puts "END OF DIAGNOSTIC REPORT"
    puts "=" * 60 + "\n"
  end

  desc "Retry all failed jobs"
  task retry_failed: :environment do
    count = SolidQueue::FailedExecution.count

    if count.zero?
      puts "No failed jobs to retry."
    else
      puts "Retrying #{count} failed jobs..."
      SolidQueue::FailedExecution.find_each do |failure|
        failure.retry
        print "."
      end
      puts "\n✓ All failed jobs queued for retry"
    end
  end

  desc "Manually fetch and update the feed (runs FetchDeveloperPortfoliosJob)"
  task update_feed: :environment do
    puts "=" * 60
    puts "UPDATING FEED AND GENERATING SCREENSHOTS"
    puts "=" * 60
    puts ""
    puts "Starting FetchDeveloperPortfoliosJob..."
    puts "This will:"
    puts "  1. Fetch and sync portfolios from the feed"
    puts "  2. Queue screenshot generation for active portfolios"
    puts ""

    begin
      FetchDeveloperPortfoliosJob.perform_now
      puts "✓ Feed update completed successfully!"
      puts ""
      puts "Screenshot jobs have been queued."
      puts "Run 'rails jobs:status' to check their progress."
    rescue => e
      puts "✗ Error updating feed:"
      puts "  #{e.message}"
      puts ""
      puts "Backtrace:"
      e.backtrace.first(5).each { |line| puts "  #{line}" }
    end
  end

  desc "Manually generate screenshots for all active portfolios"
  task generate_screenshots: :environment do
    puts "=" * 60
    puts "GENERATING SCREENSHOTS"
    puts "=" * 60
    puts ""

    portfolios = Portfolio.active
    total = portfolios.count

    puts "Found #{total} active portfolios"
    puts ""

    if total.zero?
      puts "No active portfolios found."
      return
    end

    print "Queue all screenshot jobs? (y/n): "
    response = STDIN.gets.chomp.downcase

    if response == 'y'
      puts ""
      puts "Queueing screenshot jobs..."
      portfolios.find_each.with_index do |portfolio, index|
        GeneratePortfolioScreenshotJob.perform_later(portfolio.id)
        print "."
        puts " #{index + 1}/#{total}" if (index + 1) % 50 == 0
      end
      puts "" if total % 50 != 0
      puts ""
      puts "✓ Queued #{total} screenshot jobs"
      puts ""
      puts "Run 'rails jobs:status' to check their progress."
    else
      puts "Cancelled."
    end
  end

  desc "Generate screenshot for a specific portfolio by ID"
  task :generate_screenshot, [:portfolio_id] => :environment do |t, args|
    unless args[:portfolio_id]
      puts "Usage: rails jobs:generate_screenshot[PORTFOLIO_ID]"
      puts "Example: rails jobs:generate_screenshot[123]"
      exit 1
    end

    portfolio_id = args[:portfolio_id].to_i
    portfolio = Portfolio.find_by(id: portfolio_id)

    if portfolio.nil?
      puts "✗ Portfolio with ID #{portfolio_id} not found"
      exit 1
    end

    puts "=" * 60
    puts "GENERATING SCREENSHOT"
    puts "=" * 60
    puts ""
    puts "Portfolio: #{portfolio.name}"
    puts "URL: #{portfolio.url}"
    puts "Status: #{portfolio.status}"
    puts ""

    if portfolio.active?
      puts "Generating screenshot now..."
      begin
        GeneratePortfolioScreenshotJob.perform_now(portfolio.id)
        puts "✓ Screenshot generated successfully!"
      rescue => e
        puts "✗ Error generating screenshot:"
        puts "  #{e.message}"
      end
    else
      puts "✗ Portfolio is not active (status: #{portfolio.status})"
    end
  end

  desc "Run both: update feed and generate all screenshots"
  task run_all: :environment do
    puts "\n" + "=" * 60
    puts "RUNNING ALL JOBS"
    puts "=" * 60

    puts "\nStep 1: Updating Feed"
    puts "-" * 60
    Rake::Task["jobs:update_feed"].execute

    puts "\n" + "=" * 60
    puts "COMPLETE"
    puts "=" * 60
    puts ""
    puts "Feed has been updated and screenshots queued."
    puts "Run 'rails jobs:diagnostic' to see full status."
    puts ""
  end
end

