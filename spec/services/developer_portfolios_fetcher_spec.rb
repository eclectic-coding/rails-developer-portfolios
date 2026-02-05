require 'rails_helper'

RSpec.describe DeveloperPortfoliosFetcher do
  describe '.fetch_and_sync' do
    let(:api_url) { DeveloperPortfoliosFetcher::FEED_URL }

    def stub_feed(body)
      stub_request(:get, api_url)
        .to_return(status: 200, body: body.to_json, headers: { 'Content-Type' => 'application/json' })
    end

    it 'creates new portfolios from the feed' do
      feed = [
        { 'name' => 'John Doe', 'url' => 'https://johndoe.com', 'tagline' => 'Full Stack Developer' }
      ]
      stub_feed(feed)

      expect {
        described_class.fetch_and_sync
      }.to change(Portfolio, :count).by(1)

      portfolio = Portfolio.last
      expect(portfolio.name).to eq('John Doe')
      expect(portfolio.path).to eq('https://johndoe.com')
      expect(portfolio.tagline).to eq('Full Stack Developer')
      expect(portfolio.active).to be true
    end

    it 'marks portfolios as inactive when removed from the feed' do
      # Existing portfolio in DB
      existing = create(:portfolio, name: 'To Be Removed', path: 'https://removed.com', active: true)

      # New feed without that portfolio
      feed = [
        { 'name' => 'Still Here', 'url' => 'https://still-here.com', 'tagline' => 'Present' }
      ]
      stub_feed(feed)

      described_class.fetch_and_sync

      expect(existing.reload.active).to be false
      expect(Portfolio.find_by(path: 'https://still-here.com')).to be_present
    end

    it 'marks portfolios as inactive when removed from the feed and purges their screenshots' do
      existing = create(:portfolio, name: 'To Be Removed', path: 'https://removed-with-screenshot.com', active: true)
      existing.site_screenshot.attach(
        io: StringIO.new('fake image data'),
        filename: 'screenshot.png',
        content_type: 'image/png'
      )
      expect(existing.site_screenshot).to be_attached

      feed = [
        { 'name' => 'Still Here', 'url' => 'https://still-here.com', 'tagline' => 'Present' }
      ]
      stub_feed(feed)

      described_class.fetch_and_sync

      existing.reload
      expect(existing.active).to be false
      expect(existing.site_screenshot).not_to be_attached
      expect(Portfolio.find_by(path: 'https://still-here.com')).to be_present
    end

    it 'updates name and tagline when URL stays the same' do
      portfolio = create(:portfolio,
                         name: 'Old Name',
                         path: 'https://same-url.com',
                         tagline: 'Old Tagline',
                         active: false)

      feed = [
        { 'name' => 'New Name', 'url' => 'https://same-url.com', 'tagline' => 'New Tagline' }
      ]
      stub_feed(feed)

      described_class.fetch_and_sync

      portfolio.reload
      expect(portfolio.name).to eq('New Name')
      expect(portfolio.tagline).to eq('New Tagline')
      expect(portfolio.active).to be true
    end

    it 'reuses an inactive portfolio when URL changes but name matches' do
      portfolio = create(:portfolio,
                         name: 'Same Person',
                         path: 'https://old-url.com',
                         tagline: 'Old',
                         active: false)

      feed = [
        { 'name' => 'Same Person', 'url' => 'https://new-url.com', 'tagline' => 'Updated' }
      ]
      stub_feed(feed)

      expect {
        described_class.fetch_and_sync
      }.not_to change(Portfolio, :count)

      portfolio.reload
      expect(portfolio.path).to eq('https://new-url.com')
      expect(portfolio.tagline).to eq('Updated')
      expect(portfolio.active).to be true
    end

    it 'creates a new portfolio when URL and name are both new' do
      existing = create(:portfolio,
                        name: 'Existing',
                        path: 'https://existing.com',
                        tagline: 'Existing Tagline',
                        active: true)

      feed = [
        { 'name' => 'Existing', 'url' => 'https://existing.com', 'tagline' => 'Existing Tagline' },
        { 'name' => 'New Person', 'url' => 'https://new-person.com', 'tagline' => 'New Tagline' }
      ]
      stub_feed(feed)

      expect {
        described_class.fetch_and_sync
      }.to change(Portfolio, :count).by(1)

      new_portfolio = Portfolio.find_by(path: 'https://new-person.com')
      expect(new_portfolio).to be_present
      expect(new_portfolio.name).to eq('New Person')
      expect(new_portfolio.tagline).to eq('New Tagline')
      expect(new_portfolio.active).to be true
      expect(existing.reload.active).to be true
    end

    it 'returns false and logs an error when the response is not successful' do
      stub_request(:get, api_url)
        .to_return(status: 500, body: 'Internal Server Error', headers: {})

      expect(Rails.logger).to receive(:error).with(/Failed to fetch developer portfolios: 500/)

      expect {
        result = described_class.fetch_and_sync
        expect(result).to be false
      }.not_to change(Portfolio, :count)
    end

    it 'returns false and logs an error when an exception is raised' do
      allow(Net::HTTP).to receive(:get_response).and_raise(StandardError.new('boom'))

      expect(Rails.logger).to receive(:error).with(/Error fetching developer portfolios: boom/)

      expect {
        result = described_class.fetch_and_sync
        expect(result).to be false
      }.not_to change(Portfolio, :count)
    end
  end
end
