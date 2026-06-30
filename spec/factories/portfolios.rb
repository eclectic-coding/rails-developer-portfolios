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
# Indexes
#
#  index_portfolios_on_path  (path) UNIQUE
#

FactoryBot.define do
  factory :portfolio do
    name { "MyString" }
    path { "MyString" }
    tagline { "MyText" }
    active { false }
  end
end
