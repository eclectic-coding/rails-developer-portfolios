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

class Portfolio < ApplicationRecord
  has_one_attached :site_screenshot

  validates :name, presence: true
  validates :path, presence: true, uniqueness: true

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
