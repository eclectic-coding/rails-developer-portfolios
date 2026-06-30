module ApplicationHelper
  include Pagy::Method

  def portfolio_starting_letters
    cache   = Rails.cache
    version = cache.read('portfolios_version') || 1
    cache.fetch("portfolio_starting_letters/v#{version}") do
      Portfolio.starting_letters
    end
  end
end
