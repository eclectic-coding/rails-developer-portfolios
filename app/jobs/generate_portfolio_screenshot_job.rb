class GeneratePortfolioScreenshotJob < ApplicationJob
  queue_as :default

  def perform(portfolio_id)
    portfolio = Portfolio.find_by(id: portfolio_id)
    return unless portfolio&.active?

    PortfolioScreenshotGenerator.generate_for(portfolio)
  end
end
