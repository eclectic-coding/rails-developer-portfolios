module Portfolios
  class SearchesController < ApplicationController
    def index
      redirect_to portfolios_path(params.permit(:letter, :q)), allow_other_host: false
    end
  end
end
