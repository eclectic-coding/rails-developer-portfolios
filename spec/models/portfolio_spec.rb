# == Schema Information
#
# Table name: portfolios
#
#  id         :integer          not null, primary key
#  name       :string
#  path       :string
#  tagline    :text
#  active     :boolean          default(TRUE)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

require 'rails_helper'

RSpec.describe Portfolio, type: :model do
  describe 'validations' do
    it 'is invalid without a name' do
      portfolio = build(:portfolio, name: nil)
      expect(portfolio).not_to be_valid
      expect(portfolio.errors[:name]).to include("can't be blank")
    end

    it 'is invalid without a path' do
      portfolio = build(:portfolio, path: nil)
      expect(portfolio).not_to be_valid
      expect(portfolio.errors[:path]).to include("can't be blank")
    end

    it 'enforces unique path' do
      create(:portfolio, path: 'https://unique.com')
      duplicate = build(:portfolio, path: 'https://unique.com')

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:path]).to include('has already been taken')
    end
  end

  describe '.active' do
    it 'returns only active portfolios ordered by name' do
      inactive = create(:portfolio, name: 'Zed', path: 'https://zed.com', active: false)
      alpha    = create(:portfolio, name: 'Alpha', path: 'https://alpha.com', active: true)
      beta     = create(:portfolio, name: 'Beta',  path: 'https://beta.com',  active: true)

      result = described_class.active

      expect(result).to eq([alpha, beta])
      expect(result).not_to include(inactive)
    end
  end

  describe '.starting_with' do
    it 'filters portfolios whose names start with the given letter (case-insensitive)' do
      a1 = create(:portfolio, name: 'Alice', path: 'https://alice.com')
      a2 = create(:portfolio, name: 'alpha', path: 'https://alpha.com')
      b1 = create(:portfolio, name: 'Bob',   path: 'https://bob.com')

      result = described_class.starting_with('a')

      expect(result).to match_array([a1, a2])
      expect(result).not_to include(b1)
    end

    it 'returns all records when letter is nil or blank' do
      p1 = create(:portfolio, name: 'Alice', path: 'https://alice.com')
      p2 = create(:portfolio, name: 'Bob',   path: 'https://bob.com')

      expect(described_class.starting_with(nil)).to match_array([p1, p2])
      expect(described_class.starting_with('')).to match_array([p1, p2])
    end
  end

  describe 'attachments' do
    it 'responds to site_screenshot attachment' do
      portfolio = build(:portfolio)
      expect(portfolio).to respond_to(:site_screenshot)
    end
  end
end
