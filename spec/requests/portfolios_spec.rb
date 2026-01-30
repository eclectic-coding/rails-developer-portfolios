require 'rails_helper'

RSpec.describe PortfoliosController, type: :request do
  describe 'GET /portfolios' do
    let(:sample_data) do
      [
        { 'name' => 'John Doe', 'url' => 'https://johndoe.com', 'tagline' => 'Full Stack Developer' },
        { 'name' => 'Jane Smith', 'url' => 'https://janesmith.com', 'tagline' => 'Frontend Engineer' }
      ]
    end

    before do
      allow(DeveloperPortfoliosFetcher).to receive(:fetch).and_return(sample_data)
    end

    context 'when requesting HTML' do
      it 'returns success' do
        get '/portfolios'
        expect(response).to have_http_status(:success)
      end

      it 'renders the portfolios page' do
        get '/portfolios'
        expect(response.body).to include('Developer Portfolios')
      end
    end

    context 'when requesting JSON' do
      it 'returns JSON data' do
        get '/portfolios.json'
        expect(response).to have_http_status(:success)
        expect(response.content_type).to match(/application\/json/)
      end

      it 'returns portfolios as JSON' do
        get '/portfolios.json'
        json_response = JSON.parse(response.body)
        expect(json_response).to eq(sample_data)
      end
    end
  end
end
