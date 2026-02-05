require 'rails_helper'

RSpec.describe PortfolioScreenshotGenerator, type: :service do
  describe '.generate_for' do
    let(:portfolio) { create(:portfolio, path: 'https://example.com', active: true) }

    it 'calls the node script and attaches a screenshot when successful' do
      allow_any_instance_of(PortfolioScreenshotGenerator).to receive(:system).and_return(true)
      allow(File).to receive(:exist?).and_return(true)
      fake_file = StringIO.new('fake image')
      allow(File).to receive(:open).and_yield(fake_file)

      described_class.generate_for(portfolio)

      expect(portfolio.site_screenshot).to be_attached
    end

    it 'does nothing when path is blank' do
      blank_portfolio = build(:portfolio, path: nil)

      expect(described_class.generate_for(blank_portfolio)).to be_nil
      expect(blank_portfolio.site_screenshot).not_to be_attached
    end

    it 'does nothing for inactive portfolios' do
      inactive = create(:portfolio, path: 'https://inactive.com', active: false)

      expect_any_instance_of(PortfolioScreenshotGenerator).not_to receive(:system)

      result = described_class.generate_for(inactive)

      expect(result).to be_nil
      expect(inactive.site_screenshot).not_to be_attached
    end
  end
end
