module ApplicationHelper
  include Pagy::Method

  def portfolio_starting_letters
    version = Rails.cache.read('portfolios_version') || 1
    Rails.cache.fetch("portfolio_starting_letters/v#{version}") do
      Portfolio.starting_letters
    end
  end
end
