require 'rails_helper'

RSpec.describe ApplicationHelper, type: :helper do
  describe '#portfolio_starting_letters' do
    around do |example|
      original_cache = Rails.cache
      Rails.cache = ActiveSupport::Cache::MemoryStore.new
      Rails.cache.write('portfolios_version', 1)
      example.run
    ensure
      Rails.cache = original_cache
    end

    it 'returns sorted starting letters for active portfolios' do
      create(:portfolio, name: 'Alice', path: 'https://alice.com', active: true)
      create(:portfolio, name: 'Bob',   path: 'https://bob.com',   active: true)

      expect(helper.portfolio_starting_letters).to eq(%w[A B])
    end

    it 'serves cached results within the same version' do
      create(:portfolio, name: 'Alice', path: 'https://alice.com', active: true)
      helper.portfolio_starting_letters

      create(:portfolio, name: 'Zelda', path: 'https://zelda.com', active: true)

      expect(helper.portfolio_starting_letters).to eq(%w[A])
    end

    it 'reflects new letters after portfolios_version is bumped' do
      create(:portfolio, name: 'Alice', path: 'https://alice.com', active: true)
      helper.portfolio_starting_letters

      create(:portfolio, name: 'Zelda', path: 'https://zelda.com', active: true)
      Rails.cache.write('portfolios_version', 2)

      expect(helper.portfolio_starting_letters).to eq(%w[A Z])
    end
  end
end