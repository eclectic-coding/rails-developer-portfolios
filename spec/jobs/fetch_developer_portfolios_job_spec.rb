require 'rails_helper'

RSpec.describe FetchDeveloperPortfoliosJob, type: :job do
  describe '#perform' do
    it 'delegates to DeveloperPortfoliosFetcher.fetch_and_sync' do
      expect(DeveloperPortfoliosFetcher).to receive(:fetch_and_sync)

      described_class.perform_now
    end

    it 'enqueues a screenshot job for each active portfolio' do
      # Mock the active scope and its find_each iteration
      portfolio1 = instance_double('Portfolio', id: 1)
      portfolio2 = instance_double('Portfolio', id: 2)

      active_relation = double('ActiveRelation')

      # Create an enumerator that will be returned by find_each
      # and then chain each_slice and with_index
      enumerator = [portfolio1, portfolio2].to_enum

      expect(Portfolio).to receive(:active).and_return(active_relation)
      expect(active_relation).to receive(:find_each).and_return(enumerator)

      # Mock the screenshot job enqueueing
      expect(GeneratePortfolioScreenshotJob).to receive(:perform_later).with(1)
      expect(GeneratePortfolioScreenshotJob).to receive(:perform_later).with(2)

      # Stub the fetcher since it is already covered by another example
      allow(DeveloperPortfoliosFetcher).to receive(:fetch_and_sync)

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
