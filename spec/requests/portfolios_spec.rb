require 'rails_helper'

RSpec.describe PortfoliosController, type: :request do
  describe 'GET /portfolios' do
    let!(:portfolio1) { create(:portfolio, name: 'John Doe', path: 'https://johndoe.com', tagline: 'Full Stack Developer', active: true) }
    let!(:portfolio2) { create(:portfolio, name: 'Jane Smith', path: 'https://janesmith.com', tagline: 'Frontend Engineer', active: true) }
    let!(:inactive_portfolio) { create(:portfolio, name: 'Inactive Dev', path: 'https://inactive.com', tagline: 'Should not show', active: false) }

    it 'returns success' do
      get '/portfolios'
      expect(response).to have_http_status(:success)
    end

    it 'renders the portfolios page with active portfolios' do
      get '/portfolios'

      expect(response.body).to include('Developer Portfolios').or include('Portfolios')
      expect(response.body).to include('John Doe')
      expect(response.body).to include('Jane Smith')
      expect(response.body).not_to include('Inactive Dev')
    end
  end
end
