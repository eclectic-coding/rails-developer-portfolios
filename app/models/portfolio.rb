# == Schema Information
#
# Table name: portfolios
#
#  id                      :integer          not null, primary key
#  name                    :string
#  path                    :string
#  tagline                 :text
#  active                  :boolean          default(TRUE)
#  screenshot_status       :integer          default("pending"), not null
#  screenshot_error        :text
#  screenshot_attempted_at :datetime
#  screenshot_source       :string
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#
# Indexes
#
#  index_portfolios_on_path              (path) UNIQUE
#  index_portfolios_on_screenshot_status (screenshot_status)
#

class Portfolio < ApplicationRecord
  has_one_attached :site_screenshot

  enum :screenshot_status, { pending: 0, success: 1, failed: 2 }, default: :pending

  validates :name, presence: true
  validates :path, presence: true, uniqueness: true,
                   format: { with: /\Ahttps?:\/\/[^\s]+\z/i }

  scope :active, -> { where(active: true).order(:name) }

  # Returns active portfolios optionally filtered by starting letter
  scope :starting_with, ->(letter) {
    letter.present? ? where("name ILIKE ?", "#{letter}%") : all
  }

  # Simple text search on name and tagline
  scope :search, ->(query) {
    return all if query.blank?

    where("name ILIKE :q OR tagline ILIKE :q", q: "%#{query}%")
  }

  # Returns sorted, unique starting letters for active portfolios
  def self.starting_letters
    where(active: true)
      .pluck(Arel.sql("DISTINCT UPPER(SUBSTRING(name, 1, 1))"))
      .sort
  end
end
