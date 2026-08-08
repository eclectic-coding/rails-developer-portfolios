require 'rails_helper'

RSpec.describe RetryFailedPortfolioScreenshotsJob, type: :job do
  include ActiveJob::TestHelper

  describe '#perform' do
    it 'enqueues a screenshot job for pending and failed active portfolios' do
      ActiveJob::Base.queue_adapter = :test

      pending_portfolio = create(:portfolio, active: true)
      failed_portfolio = create(:portfolio, :with_failed_screenshot, active: true)
      create(:portfolio, :with_successful_screenshot, active: true)
      create(:portfolio, :with_failed_screenshot, active: false)

      described_class.perform_now

      enqueued_ids = enqueued_jobs
        .select { |job| job[:job] == GeneratePortfolioScreenshotJob }
        .map { |job| job[:args].first }

      expect(enqueued_ids).to match_array([pending_portfolio.id, failed_portfolio.id])
    end
  end
end