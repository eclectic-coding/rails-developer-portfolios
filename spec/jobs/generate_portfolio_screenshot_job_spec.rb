require 'rails_helper'

RSpec.describe GeneratePortfolioScreenshotJob, type: :job do
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
end

