module ApplicationHelper
  include Pagy::Frontend

  def portfolio_starting_letters
    Rails.cache.fetch('portfolio_starting_letters') do
      Portfolio.starting_letters
    end
  end
end
