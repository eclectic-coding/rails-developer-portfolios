require 'rails_helper'

RSpec.describe PortfolioOgImageFetcher do
  describe '.fetch' do
    let(:url) { 'https://example.com' }

    def stub_page(html, status: 200)
      stub_request(:get, url).to_return(status: status, body: html, headers: { 'Content-Type' => 'text/html' })
    end

    def stub_image(image_url, body: 'fake image bytes', content_type: 'image/png', status: 200)
      stub_request(:get, image_url).to_return(status: status, body: body, headers: { 'Content-Type' => content_type })
    end

    it 'downloads the og:image when present' do
      stub_page(<<~HTML)
        <html><head><meta property="og:image" content="https://example.com/preview.png"></head></html>
      HTML
      stub_image('https://example.com/preview.png')

      result = described_class.fetch(url)

      expect(result.image_data).to eq('fake image bytes')
      expect(result.content_type).to eq('image/png')
    end

    it 'falls back to twitter:image when og:image is absent' do
      stub_page(<<~HTML)
        <html><head><meta name="twitter:image" content="https://example.com/twitter.png"></head></html>
      HTML
      stub_image('https://example.com/twitter.png')

      result = described_class.fetch(url)

      expect(result.image_data).to eq('fake image bytes')
    end

    it 'resolves relative image URLs against the page URL' do
      stub_page(<<~HTML)
        <html><head><meta property="og:image" content="/assets/preview.png"></head></html>
      HTML
      stub_image('https://example.com/assets/preview.png')

      result = described_class.fetch(url)

      expect(result.image_data).to eq('fake image bytes')
    end

    it 'returns nil when there is no og:image or twitter:image tag' do
      stub_page('<html><head></head></html>')

      expect(described_class.fetch(url)).to be_nil
    end

    it 'returns nil when the page cannot be fetched' do
      stub_page('', status: 500)

      expect(described_class.fetch(url)).to be_nil
    end

    it 'returns nil when the network raises' do
      stub_request(:get, url).to_raise(Net::OpenTimeout)

      expect(described_class.fetch(url)).to be_nil
    end

    it 'returns nil when the referenced content type is not an image' do
      stub_page(<<~HTML)
        <html><head><meta property="og:image" content="https://example.com/preview.png"></head></html>
      HTML
      stub_image('https://example.com/preview.png', content_type: 'text/html')

      expect(described_class.fetch(url)).to be_nil
    end

    it 'returns nil when the image exceeds the size cap' do
      stub_page(<<~HTML)
        <html><head><meta property="og:image" content="https://example.com/preview.png"></head></html>
      HTML
      stub_image('https://example.com/preview.png', body: 'x' * (described_class::MAX_IMAGE_BYTES + 1))

      expect(described_class.fetch(url)).to be_nil
    end
  end
end