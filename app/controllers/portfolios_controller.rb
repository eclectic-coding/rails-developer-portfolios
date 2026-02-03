class PortfoliosController < ApplicationController
  def index
    redirect_to portfolios_searches_path(params.permit(:letter, :q)), allow_other_host: false
  end
end
