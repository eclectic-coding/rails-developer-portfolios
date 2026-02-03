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
  validates :name, presence: true
  validates :path, presence: true, uniqueness: true

  scope :active, -> { where(active: true).order(:name) }

  # Returns active portfolios optionally filtered by starting letter
  scope :starting_with, ->(letter) {
    letter.present? ? where("name ILIKE ?", "#{letter}%") : all
  }

  # Returns sorted, unique starting letters for active portfolios
  def self.starting_letters
    where(active: true)
      .pluck(Arel.sql("DISTINCT UPPER(SUBSTRING(name, 1, 1))"))
      .sort
  end
end
