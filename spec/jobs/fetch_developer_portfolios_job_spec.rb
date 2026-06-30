require 'rails_helper'

RSpec.describe FetchDeveloperPortfoliosJob, type: :job do
  describe '#perform' do
    it 'delegates to DeveloperPortfoliosFetcher.fetch_and_sync' do
      expect(DeveloperPortfoliosFetcher).to receive(:fetch_and_sync)

      described_class.perform_now
    end

    it 'enqueues a screenshot job for each active portfolio' do
      portfolio1 = instance_double('Portfolio', id: 1)
      portfolio2 = instance_double('Portfolio', id: 2)

      active_relation = double('ActiveRelation')
      enumerator = [portfolio1, portfolio2].to_enum

      expect(Portfolio).to receive(:active).and_return(active_relation)
      expect(active_relation).to receive(:find_each).and_return(enumerator)

      expect(GeneratePortfolioScreenshotJob).to receive(:perform_later).with(1)
      expect(GeneratePortfolioScreenshotJob).to receive(:perform_later).with(2)

      allow(DeveloperPortfoliosFetcher).to receive(:fetch_and_sync)

      described_class.perform_now
    end

    it 'enqueues delayed screenshot jobs for portfolios in batches after the first' do
      portfolios = (1..11).map { |i| instance_double('Portfolio', id: i) }
      active_relation = double('ActiveRelation')

      allow(Portfolio).to receive(:active).and_return(active_relation)
      allow(active_relation).to receive(:find_each).and_return(portfolios.to_enum)
      allow(DeveloperPortfoliosFetcher).to receive(:fetch_and_sync)

      # First batch (indices 1–10): immediate
      (1..10).each { |i| expect(GeneratePortfolioScreenshotJob).to receive(:perform_later).with(i) }

      # Second batch starts at batch_index 1: delayed by 1 * DELAY_SECONDS
      delay = described_class::DELAY_SECONDS.seconds
      delayed_proxy = double('delayed_proxy')
      expect(GeneratePortfolioScreenshotJob).to receive(:set).with(wait: delay).and_return(delayed_proxy)
      expect(delayed_proxy).to receive(:perform_later).with(11)

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
