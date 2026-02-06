module ApplicationHelper
  # Returns the unique starting letters for all active portfolios, cached.
  # This mirrors the logic previously in `Portfolios::SearchesController#index`.
  def portfolio_starting_letters
    Rails.cache.fetch('portfolio_starting_letters') do
      Portfolio.starting_letters
    end
  end
end
