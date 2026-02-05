class FetchDeveloperPortfoliosJob < ApplicationJob
  queue_as :default

  def perform
    DeveloperPortfoliosFetcher.fetch_and_sync

    Portfolio.active.find_each do |portfolio|
      GeneratePortfolioScreenshotJob.perform_later(portfolio.id)
    end
  end
end
