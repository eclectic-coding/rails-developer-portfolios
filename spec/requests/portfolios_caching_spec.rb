require 'rails_helper'

RSpec.describe 'Portfolios caching', type: :request do
  describe 'GET /portfolios' do
    let!(:portfolio) { create(:portfolio, name: 'Cached Dev', path: 'https://cached.dev', tagline: 'Cached Tagline', active: true) }

    it 'renders successfully and can be requested multiple times' do
      # First request: should render and potentially populate the fragment cache
      get '/portfolios', params: { letter: 'C' }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Cached Dev')

      # Second request: same params, should still render successfully (cache hit path)
      get '/portfolios', params: { letter: 'C' }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Cached Dev')
    end

    context 'when the fragment cache is warm and a screenshot is later regenerated' do
      around do |example|
        original_cache = Rails.cache
        original_perform_caching = ApplicationController.perform_caching

        Rails.cache = ActiveSupport::Cache::MemoryStore.new
        ApplicationController.perform_caching = true

        example.run
      ensure
        Rails.cache = original_cache
        ApplicationController.perform_caching = original_perform_caching
      end

      it "reflects a portfolio's new screenshot instead of serving a stale (purged) blob URL" do
        portfolio.site_screenshot.attach(
          io: StringIO.new('first image'), filename: 'first-screenshot.png', content_type: 'image/png'
        )
        portfolio.update!(screenshot_status: :success, screenshot_source: 'og_image', screenshot_attempted_at: Time.current)

        get '/portfolios', params: { letter: 'C' }

        expect(response.body).to include('first-screenshot.png')

        # Regenerating the screenshot replaces (and purges) the old blob and bumps
        # screenshot_attempted_at - this is what PortfolioScreenshotGenerator#mark_success
        # does on every successful re-run.
        portfolio.site_screenshot.attach(
          io: StringIO.new('second image'), filename: 'second-screenshot.png', content_type: 'image/png'
        )
        portfolio.update!(screenshot_status: :success, screenshot_source: 'og_image', screenshot_attempted_at: Time.current)

        get '/portfolios', params: { letter: 'C' }

        expect(response.body).to include('second-screenshot.png')
        expect(response.body).not_to include('first-screenshot.png')
      end
    end
  end
end
