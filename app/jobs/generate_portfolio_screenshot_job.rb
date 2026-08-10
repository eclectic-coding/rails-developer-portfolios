class GeneratePortfolioScreenshotJob < ApplicationJob
  queue_as :default

  # Never more than 3 screenshot jobs (og:image fetches or Playwright
  # captures) running at once, regardless of JOB_CONCURRENCY/thread count.
  limits_concurrency to: 3, key: ->(*) { "portfolio_screenshot_generation" }, duration: 5.minutes

  retry_on PortfolioScreenshotGenerator::CaptureError, wait: :polynomially_longer, attempts: 3 do |job, error|
    portfolio_id = job.arguments.first
    Portfolio.where(id: portfolio_id).update_all(
      screenshot_status: Portfolio.screenshot_statuses[:failed],
      screenshot_error: error.message.to_s.truncate(500),
      screenshot_attempted_at: Time.current,
      screenshot_source: nil
    )
    Rails.logger.error "GeneratePortfolioScreenshotJob exhausted retries for Portfolio##{portfolio_id}: #{error.message}"
  end

  def perform(portfolio_id)
    portfolio = Portfolio.find_by(id: portfolio_id)
    return unless portfolio&.active?

    PortfolioScreenshotGenerator.generate_for(portfolio)
  end
end
