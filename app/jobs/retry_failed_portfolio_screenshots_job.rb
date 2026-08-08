class RetryFailedPortfolioScreenshotsJob < ApplicationJob
  queue_as :default

  # Sweeps portfolios that never got a screenshot or whose last attempt
  # failed, so they get retried well before the next weekly feed sync.
  def perform
    Portfolio.active.where(screenshot_status: [:pending, :failed]).find_each do |portfolio|
      GeneratePortfolioScreenshotJob.perform_later(portfolio.id)
    end
  end
end
