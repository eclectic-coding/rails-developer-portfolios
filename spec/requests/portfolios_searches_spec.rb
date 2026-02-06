require 'rails_helper'

RSpec.describe Portfolios::SearchesController, type: :request do
  describe 'GET /portfolios/searches' do
    let!(:portfolio) { create(:portfolio, name: 'Searchable Dev', path: 'https://searchable.dev', tagline: 'Searchable Tagline', active: true) }

    it 'redirects to the main portfolios index with the same params' do
      get '/portfolios/searches', params: { letter: 'S', q: 'Search' }

      expect(response).to have_http_status(:found)
      expect(response).to redirect_to(portfolios_path(letter: 'S', q: 'Search'))
    end

    it 'results in a successful page load after following the redirect' do
      get '/portfolios/searches', params: { letter: 'S', q: 'Search' }
      follow_redirect!

      expect(response).to have_http_status(:ok)
    end
  end
end

