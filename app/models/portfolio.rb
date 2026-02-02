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
end
