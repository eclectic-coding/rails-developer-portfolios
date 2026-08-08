require 'rails_helper'

RSpec.describe PortfolioScreenshotGenerator, type: :service do
  describe '.generate_for' do
    let(:portfolio) { create(:portfolio, path: 'https://example.com', active: true) }
    let(:og_result) { PortfolioOgImageFetcher::Result.new(image_data: 'fake image data', content_type: 'image/png') }

    it 'prefers the og:image when available and does not invoke Playwright' do
      allow(PortfolioOgImageFetcher).to receive(:fetch).with(portfolio.path).and_return(og_result)
      expect_any_instance_of(described_class).not_to receive(:system)

      result = described_class.generate_for(portfolio)

      expect(result).to eq(portfolio)
      expect(portfolio.site_screenshot).to be_attached
      expect(portfolio.reload).to have_attributes(
        screenshot_status: 'success',
        screenshot_source: 'og_image',
        screenshot_error: nil
      )
    end

    it 'falls back to Playwright when no og:image is found' do
      allow(PortfolioOgImageFetcher).to receive(:fetch).and_return(nil)

      frozen_time = Time.now
      allow(Time).to receive(:now).and_return(frozen_time)

      output_dir = PortfolioScreenshotGenerator::OUTPUT_DIR
      tmpfile = output_dir.join("portfolio_#{portfolio.id}_#{frozen_time.to_i}.png")
      FileUtils.mkdir_p(output_dir)
      File.write(tmpfile, 'fake image data')

      allow_any_instance_of(described_class).to receive(:system).and_return(true)

      result = described_class.generate_for(portfolio)

      expect(result).to eq(portfolio)
      expect(portfolio.site_screenshot).to be_attached
      expect(portfolio.reload).to have_attributes(screenshot_status: 'success', screenshot_source: 'playwright')
    ensure
      FileUtils.rm_f(tmpfile) if tmpfile
    end

    it 'falls back to Playwright when attaching the og:image raises' do
      allow(PortfolioOgImageFetcher).to receive(:fetch).and_return(og_result)

      attach_calls = 0
      allow_any_instance_of(ActiveStorage::Attached::One).to receive(:attach).and_wrap_original do |original, *args|
        attach_calls += 1
        raise StandardError, 'disk full' if attach_calls == 1

        original.call(*args)
      end

      frozen_time = Time.now
      allow(Time).to receive(:now).and_return(frozen_time)

      output_dir = PortfolioScreenshotGenerator::OUTPUT_DIR
      tmpfile = output_dir.join("portfolio_#{portfolio.id}_#{frozen_time.to_i}.png")
      FileUtils.mkdir_p(output_dir)
      File.write(tmpfile, 'fake image data')

      allow_any_instance_of(described_class).to receive(:system).and_return(true)

      result = described_class.generate_for(portfolio)

      expect(result).to eq(portfolio)
      expect(portfolio.reload).to have_attributes(screenshot_status: 'success', screenshot_source: 'playwright')
    ensure
      FileUtils.rm_f(tmpfile) if tmpfile
    end

    it 'does nothing when path is blank' do
      blank_portfolio = build(:portfolio, path: nil)

      expect(described_class.generate_for(blank_portfolio)).to be_nil
      expect(blank_portfolio.site_screenshot).not_to be_attached
    end

    it 'does nothing for inactive portfolios' do
      inactive = create(:portfolio, path: 'https://inactive.com', active: false)

      expect(PortfolioOgImageFetcher).not_to receive(:fetch)

      result = described_class.generate_for(inactive)

      expect(result).to be_nil
      expect(inactive.site_screenshot).not_to be_attached
    end

    it 'raises CaptureError when both og:image and Playwright fail, without changing status' do
      allow(PortfolioOgImageFetcher).to receive(:fetch).and_return(nil)
      allow_any_instance_of(described_class).to receive(:system).and_raise(StandardError.new('node not found'))

      expect {
        described_class.generate_for(portfolio)
      }.to raise_error(PortfolioScreenshotGenerator::CaptureError, /node not found/)

      expect(portfolio.site_screenshot).not_to be_attached
      expect(portfolio.reload.screenshot_status).to eq('pending')
    end
  end
end
