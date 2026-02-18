module ApplicationHelper
  include Pagy::Method

  def portfolio_starting_letters
    # Try to use cache, but fall back to direct query if cache tables don't exist
    begin
      Rails.cache.fetch('portfolio_starting_letters') do
        Portfolio.starting_letters
      end
    rescue ActiveRecord::StatementInvalid, PG::UndefinedTable
      # Cache tables don't exist yet, query directly
      Portfolio.starting_letters
    end
  end
end
