class RetryFailedPortfolioScreenshotsJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: :polynomially_longer, attempts: 3 do |job, error|
    AdminMailer.job_failure_report(job.class.name, error, job.arguments).deliver_now
    Rails.logger.error "#{job.class.name} exhausted retries: #{error.message}"
  end

  # Sweeps portfolios that never got a screenshot or whose last attempt
  # failed, so they get retried well before the next weekly feed sync.
  def perform
    Portfolio.active.where(screenshot_status: [:pending, :failed]).find_each do |portfolio|
      GeneratePortfolioScreenshotJob.perform_later(portfolio.id)
    end
  end
end
