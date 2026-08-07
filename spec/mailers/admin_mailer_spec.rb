require 'rails_helper'

RSpec.describe AdminMailer, type: :mailer do
  describe '#feed_sync_report' do
    let(:admin_email) { 'admin@example.com' }

    before do
      allow(Rails.application.credentials).to receive(:admin_email).and_return(admin_email)
    end

    context 'when the sync succeeded' do
      let(:result) do
        DeveloperPortfoliosFetcher::SyncResult.new(
          success: true,
          error: nil,
          created: %w[New\ Person],
          updated: %w[Existing\ Person],
          deactivated: %w[Removed\ Person],
          skipped: [{ name: 'Bad Entry', url: 'https:bad-url.com', error: "Path must be an http or https URL" }],
          total: 4
        )
      end

      let(:mail) { described_class.feed_sync_report(result) }

      it 'sends to the configured admin email with a success subject' do
        expect(mail.to).to eq([admin_email])
        expect(mail.subject).to eq('[Developer Portfolios] Feed sync succeeded')
      end

      it 'includes the counts and details in the body' do
        expect(mail.text_part.body.to_s).to include('New Person')
        expect(mail.text_part.body.to_s).to include('Bad Entry')
        expect(mail.text_part.body.to_s).to include('Removed Person')
        expect(mail.html_part.body.to_s).to include('New Person')
      end
    end

    context 'when the sync failed' do
      let(:result) do
        DeveloperPortfoliosFetcher::SyncResult.new(
          success: false, error: '500 Internal Server Error', created: [], updated: [],
          deactivated: [], skipped: [], total: nil
        )
      end

      let(:mail) { described_class.feed_sync_report(result) }

      it 'sends a failure subject and includes the error' do
        expect(mail.subject).to eq('[Developer Portfolios] Feed sync FAILED')
        expect(mail.text_part.body.to_s).to include('500 Internal Server Error')
      end
    end

    context 'when no admin_email is configured' do
      before do
        allow(Rails.application.credentials).to receive(:admin_email).and_return(nil)
      end

      let(:result) do
        DeveloperPortfoliosFetcher::SyncResult.new(
          success: true, error: nil, created: [], updated: [], deactivated: [], skipped: [], total: 0
        )
      end

      it 'does not send an email' do
        expect { described_class.feed_sync_report(result).deliver_now }
          .not_to change { ActionMailer::Base.deliveries.count }
      end
    end
  end
end
