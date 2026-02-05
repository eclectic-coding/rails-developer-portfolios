require 'rails_helper'

RSpec.describe 'Portfolios caching', type: :request do
  describe 'GET /portfolios (via searches#index)' do
    let!(:portfolio) { create(:portfolio, name: 'Cached Dev', path: 'https://cached.dev', tagline: 'Cached Tagline', active: true) }

    it 'renders successfully and can be requested multiple times' do
      # First request: should render and potentially populate the fragment cache
      get '/portfolios', params: { letter: 'C' }
      follow_redirect!

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Cached Dev')

      # Second request: same params, should still render successfully (cache hit path)
      get '/portfolios', params: { letter: 'C' }
      follow_redirect!

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Cached Dev')
    end
  end
end
