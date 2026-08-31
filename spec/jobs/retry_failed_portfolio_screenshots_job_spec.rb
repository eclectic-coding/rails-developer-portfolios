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

  describe 'when perform raises an unhandled error' do
    before { ActiveJob::Base.queue_adapter = :test }

    it 'retries with backoff and emails the admin once retries are exhausted' do
      failure_mail = instance_double(ActionMailer::MessageDelivery, deliver_now: true)
      allow(Portfolio).to receive(:active).and_raise(StandardError, 'boom')
      allow(AdminMailer).to receive(:job_failure_report).and_return(failure_mail)

      perform_enqueued_jobs(only: described_class) do
        described_class.perform_later
      end

      expect(AdminMailer).to have_received(:job_failure_report).with('RetryFailedPortfolioScreenshotsJob', instance_of(StandardError), [])
      expect(failure_mail).to have_received(:deliver_now)
    end
  end
end
