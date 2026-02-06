class PortfoliosController < ApplicationController
  def index
    @query = params[:q].to_s.presence

    @portfolios = Portfolio.active.search(@query)

    respond_to do |format|
      format.html
    end
  end
end
