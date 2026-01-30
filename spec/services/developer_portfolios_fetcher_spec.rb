require 'rails_helper'

RSpec.describe DeveloperPortfoliosFetcher do
  let(:api_url) { 'https://raw.githubusercontent.com/emmabostian/developer-portfolios/master/feed.json' }
  let(:sample_response) { [{ 'name' => 'Test Portfolio', 'url' => 'https://example.com', 'tagline' => 'Developer' }].to_json }

  # Use memory store for testing caching behavior
  around do |example|
    original_cache_store = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    example.run
    Rails.cache = original_cache_store
  end

  after do
    Rails.cache.delete(DeveloperPortfoliosFetcher::CACHE_KEY)
  end

  describe '.fetch' do
    context 'when data is not cached' do
      before do
        Rails.cache.delete(DeveloperPortfoliosFetcher::CACHE_KEY)
        stub_request(:get, api_url)
          .to_return(status: 200, body: sample_response, headers: { 'Content-Type' => 'application/json' })
      end

      it 'fetches data from the API' do
        result = described_class.fetch
        expect(result).to be_an(Array)
        expect(result.first['name']).to eq('Test Portfolio')
      end
    end
  end

  describe '.fetch_and_cache' do
    before do
      stub_request(:get, api_url)
        .to_return(status: 200, body: sample_response, headers: { 'Content-Type' => 'application/json' })
    end

    it 'fetches and caches data' do
      result = described_class.fetch_and_cache
      expect(result).to be_an(Array)

      cached = Rails.cache.read(DeveloperPortfoliosFetcher::CACHE_KEY)
      expect(cached).to eq(result)
    end
  end

  describe '.clear_cache' do
    it 'removes cached data' do
      Rails.cache.write(DeveloperPortfoliosFetcher::CACHE_KEY, ['test'])
      described_class.clear_cache
      expect(Rails.cache.read(DeveloperPortfoliosFetcher::CACHE_KEY)).to be_nil
    end
  end
end
