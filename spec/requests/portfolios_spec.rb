require 'rails_helper'

RSpec.describe PortfoliosController, type: :request do
  describe 'GET /portfolios' do
    let!(:portfolio1) { create(:portfolio, name: 'John Doe', path: 'https://johndoe.com', tagline: 'Full Stack Developer', active: true) }
    let!(:portfolio2) { create(:portfolio, name: 'Jane Smith', path: 'https://janesmith.com', tagline: 'Frontend Engineer', active: true) }
    let!(:portfolio3) { create(:portfolio, name: 'Alice Johnson', path: 'https://alice.com', tagline: 'Backend Engineer', active: true) }
    let!(:portfolio4) { create(:portfolio, name: 'Sam Search', path: 'https://samsearch.com', tagline: 'Search Specialist', active: true) }
    let!(:inactive_portfolio) { create(:portfolio, name: 'Inactive Dev', path: 'https://inactive.com', tagline: 'Should not show', active: false) }

    it 'returns success' do
      get '/portfolios'

      expect(response).to have_http_status(:success)
    end

    it 'returns success when filtering by starting letter' do
      # Request only portfolios starting with "J"
      get '/portfolios', params: { letter: 'J' }

      expect(response).to have_http_status(:success)
    end

    it 'returns success when filtering by search query' do
      # Search for portfolios with "Search" in name or tagline
      get '/portfolios', params: { q: 'Search' }

      expect(response).to have_http_status(:success)
    end
  end
end
