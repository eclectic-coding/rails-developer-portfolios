class PortfoliosController < ApplicationController
  def index
    @letter = params[:letter].presence

    base_scope = Portfolio.active

    # Total active portfolios, regardless of filter
    @total_portfolios_count = base_scope.count

    # Filtered portfolios for the current letter (or all when no letter)
    @portfolios = base_scope.starting_with(@letter)

    # Unique starting letters for all active portfolios
    @letters = Portfolio.starting_letters

    respond_to do |format|
      format.html
    end
  end
end
