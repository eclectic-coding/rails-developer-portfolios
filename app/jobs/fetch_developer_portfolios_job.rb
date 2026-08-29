class FetchDeveloperPortfoliosJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: :polynomially_longer, attempts: 3 do |job, error|
    AdminMailer.job_failure_report(job.class.name, error, job.arguments).deliver_now
    Rails.logger.error "#{job.class.name} exhausted retries: #{error.message}"
  end

  def perform
    result = DeveloperPortfoliosFetcher.fetch_and_sync
    AdminMailer.feed_sync_report(result).deliver_now

    # GeneratePortfolioScreenshotJob caps its own concurrency (see
    # limits_concurrency), so it's safe to enqueue everything immediately
    # rather than staggering batches with artificial delays.
    Portfolio.active.find_each do |portfolio|
      GeneratePortfolioScreenshotJob.perform_later(portfolio.id)
    end
  end
end
