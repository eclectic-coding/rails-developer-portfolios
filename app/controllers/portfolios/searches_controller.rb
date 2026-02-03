module Portfolios
  class SearchesController < ApplicationController
    def index
      raw_letter = params[:letter].to_s
      sanitized_letter = raw_letter.strip

      @letter =
        if sanitized_letter.present? && sanitized_letter.match?(/\A[a-zA-Z0-9]\z/)
          sanitized_letter
        else
          nil
        end
      @query  = params[:q].to_s.presence

      base_scope = Portfolio.active

      # Total active portfolios, regardless of filter or search
      @total_portfolios_count = base_scope.count

      # Filtered portfolios for the current letter and search query
      @portfolios = base_scope
        .starting_with(@letter)
        .search(@query)

      # Unique starting letters for all active portfolios (not filtered by search)
      @letters = Portfolio.starting_letters

      respond_to do |format|
        format.html { render template: 'portfolios/index' }
      end
    end
  end
end
