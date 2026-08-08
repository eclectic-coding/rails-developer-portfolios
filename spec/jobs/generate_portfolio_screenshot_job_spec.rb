require 'rails_helper'

RSpec.describe GeneratePortfolioScreenshotJob, type: :job do
  include ActiveJob::TestHelper

  let(:portfolio) { create(:portfolio, path: 'https://example.com', active: true) }

  it 'generates a screenshot for an active portfolio' do
    expect(PortfolioScreenshotGenerator).to receive(:generate_for).with(portfolio)

    described_class.perform_now(portfolio.id)
  end

  it 'does nothing for a missing portfolio' do
    expect(PortfolioScreenshotGenerator).not_to receive(:generate_for)

    described_class.perform_now(-1)
  end

  it 'does nothing for an inactive portfolio' do
    inactive = create(:portfolio, path: 'https://inactive.com', active: false)

    expect(PortfolioScreenshotGenerator).not_to receive(:generate_for)

    described_class.perform_now(inactive.id)
  end

  describe 'when generation raises CaptureError' do
    before { ActiveJob::Base.queue_adapter = :test }

    it 'retries with backoff and records the failure on the portfolio once retries are exhausted' do
      allow(PortfolioScreenshotGenerator).to receive(:generate_for)
        .and_raise(PortfolioScreenshotGenerator::CaptureError, 'boom')

      perform_enqueued_jobs(only: described_class) do
        described_class.perform_later(portfolio.id)
      end

      expect(portfolio.reload).to have_attributes(
        screenshot_status: 'failed',
        screenshot_error: 'boom',
        screenshot_source: nil
      )
      expect(portfolio.screenshot_attempted_at).to be_present
    end

    it 'clears a stale screenshot_source when a previously-successful portfolio later fails' do
      portfolio.update!(screenshot_status: :success, screenshot_source: 'og_image')

      allow(PortfolioScreenshotGenerator).to receive(:generate_for)
        .and_raise(PortfolioScreenshotGenerator::CaptureError, 'boom')

      perform_enqueued_jobs(only: described_class) do
        described_class.perform_later(portfolio.id)
      end

      expect(portfolio.reload).to have_attributes(screenshot_status: 'failed', screenshot_source: nil)
    end
  end
end
