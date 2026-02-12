class PortfoliosController < ApplicationController
  def index
    @query = params[:q].to_s.presence
    @letter = params[:letter].to_s.presence

    portfolios_scope = Portfolio.active
                                .starting_with(@letter)
                                .search(@query)

    @pagy, @portfolios = pagy(portfolios_scope, items: 12)

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end
end
