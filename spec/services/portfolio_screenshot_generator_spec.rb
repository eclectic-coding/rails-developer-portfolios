require 'rails_helper'

RSpec.describe PortfolioScreenshotGenerator, type: :service do
  describe '.generate_for' do
    let(:portfolio) { create(:portfolio, path: 'https://example.com', active: true) }

    it 'calls the node script, attaches a screenshot, and returns the portfolio' do
      frozen_time = Time.now
      allow(Time).to receive(:now).and_return(frozen_time)

      output_dir = PortfolioScreenshotGenerator::OUTPUT_DIR
      tmpfile = output_dir.join("portfolio_#{portfolio.id}_#{frozen_time.to_i}.png")
      FileUtils.mkdir_p(output_dir)
      File.write(tmpfile, 'fake image data')

      allow_any_instance_of(described_class).to receive(:system).and_return(true)

      result = described_class.generate_for(portfolio)

      expect(result).to eq(portfolio)
      expect(portfolio.site_screenshot).to be_attached
    ensure
      FileUtils.rm_f(tmpfile) if tmpfile
    end

    it 'does nothing when path is blank' do
      blank_portfolio = build(:portfolio, path: nil)

      expect(described_class.generate_for(blank_portfolio)).to be_nil
      expect(blank_portfolio.site_screenshot).not_to be_attached
    end

    it 'returns nil and logs an error when generation raises' do
      allow_any_instance_of(described_class).to receive(:system).and_raise(StandardError.new('node not found'))
      expect(Rails.logger).to receive(:error).with(/Failed to generate screenshot for Portfolio##{portfolio.id}/)

      result = described_class.generate_for(portfolio)

      expect(result).to be_nil
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
