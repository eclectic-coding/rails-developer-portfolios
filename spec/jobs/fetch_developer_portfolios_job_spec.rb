require 'rails_helper'

RSpec.describe FetchDeveloperPortfoliosJob, type: :job do
  describe '#perform' do
    it 'delegates to DeveloperPortfoliosFetcher.fetch_and_sync' do
      expect(DeveloperPortfoliosFetcher).to receive(:fetch_and_sync)

      described_class.perform_now
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
end
