class FetchDeveloperPortfoliosJob < ApplicationJob
  queue_as :default

  BATCH_SIZE = 10
  DELAY_SECONDS = 30

  def perform
    DeveloperPortfoliosFetcher.fetch_and_sync

    # Generate screenshots in batches to avoid overwhelming resources
    Portfolio.active.find_each.each_slice(BATCH_SIZE).with_index do |batch, batch_index|
      batch.each do |portfolio|
        # Use set with a delay for batches after the first
        if batch_index > 0
          GeneratePortfolioScreenshotJob.set(wait: batch_index * DELAY_SECONDS.seconds).perform_later(portfolio.id)
        else
          GeneratePortfolioScreenshotJob.perform_later(portfolio.id)
        end
      end
    end
  end
end
