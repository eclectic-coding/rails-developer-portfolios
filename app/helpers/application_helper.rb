module ApplicationHelper
  include Pagy::Method

  def portfolio_starting_letters
    Rails.cache.fetch('portfolio_starting_letters') do
      Portfolio.starting_letters
    end
  end
end
