class FetchDeveloperPortfoliosJob < ApplicationJob
  queue_as :default

  def perform
    DeveloperPortfoliosFetcher.fetch_and_cache
  end
end
