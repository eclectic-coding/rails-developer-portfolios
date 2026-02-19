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

    portfolios = Portfolio.active.where(screenshot_status: nil)
                          .or(Portfolio.active.where(screenshot_status: "pending"))

    puts "Active portfolios without completed screenshots: #{portfolios.count}"
    puts ""

    if portfolios.any?
      puts "Sample (first 10):"
      portfolios.limit(10).each do |portfolio|
        puts "  #{portfolio.name} (ID: #{portfolio.id}) - Status: #{portfolio.screenshot_status || 'not started'}"
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
end

