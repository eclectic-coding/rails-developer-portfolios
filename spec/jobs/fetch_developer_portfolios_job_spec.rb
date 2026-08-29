require 'rails_helper'

RSpec.describe FetchDeveloperPortfoliosJob, type: :job do
  include ActiveJob::TestHelper

  let(:sync_result) do
    DeveloperPortfoliosFetcher::SyncResult.new(
      success: true, error: nil, created: [], updated: [], deactivated: [], skipped: [], total: 0
    )
  end
  let(:mail_message) { instance_double(ActionMailer::MessageDelivery, deliver_now: true) }

  before do
    allow(AdminMailer).to receive(:feed_sync_report).and_return(mail_message)
  end

  describe '#perform' do
    it 'delegates to DeveloperPortfoliosFetcher.fetch_and_sync' do
      expect(DeveloperPortfoliosFetcher).to receive(:fetch_and_sync).and_return(sync_result)

      described_class.perform_now
    end

    it 'emails the site admin a report of the sync result' do
      allow(DeveloperPortfoliosFetcher).to receive(:fetch_and_sync).and_return(sync_result)

      expect(AdminMailer).to receive(:feed_sync_report).with(sync_result).and_return(mail_message)
      expect(mail_message).to receive(:deliver_now)

      described_class.perform_now
    end

    it 'enqueues a screenshot job for every active portfolio immediately, with no delay' do
      ActiveJob::Base.queue_adapter = :test
      active_portfolios = create_list(:portfolio, 3, active: true)
      create(:portfolio, active: false)

      allow(DeveloperPortfoliosFetcher).to receive(:fetch_and_sync).and_return(sync_result)

      described_class.perform_now

      enqueued_ids = enqueued_jobs
        .select { |job| job[:job] == GeneratePortfolioScreenshotJob }
        .map { |job| job[:args].first }

      expect(enqueued_ids).to match_array(active_portfolios.map(&:id))
    end
  end

  describe 'queueing' do
    it 'is enqueued on the default queue' do
      ActiveJob::Base.queue_adapter = :test

      expect {
        described_class.perform_later
      }.to have_enqueued_job(described_class).on_queue('default')
    end
  end

  describe 'when fetch_and_sync raises an unhandled error' do
    before { ActiveJob::Base.queue_adapter = :test }

    it 'retries with backoff and emails the admin once retries are exhausted' do
      failure_mail = instance_double(ActionMailer::MessageDelivery, deliver_now: true)
      allow(DeveloperPortfoliosFetcher).to receive(:fetch_and_sync).and_raise(StandardError, 'boom')
      allow(AdminMailer).to receive(:job_failure_report).and_return(failure_mail)

      perform_enqueued_jobs(only: described_class) do
        described_class.perform_later
      end

      expect(AdminMailer).to have_received(:job_failure_report).with('FetchDeveloperPortfoliosJob', instance_of(StandardError), [])
      expect(failure_mail).to have_received(:deliver_now)
    end
  end
end
