class PortfoliosController < ApplicationController
  def index
    @portfolios = DeveloperPortfoliosFetcher.fetch

    respond_to do |format|
      format.html # if you want to render a view
      format.json { render json: @portfolios }
    end
  end
end
