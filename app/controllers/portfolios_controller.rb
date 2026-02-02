class PortfoliosController < ApplicationController
  def index
    @portfolios = Portfolio.active

    respond_to do |format|
      format.html
    end
  end
end
