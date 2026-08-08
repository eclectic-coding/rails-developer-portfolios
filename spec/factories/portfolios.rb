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

FactoryBot.define do
  factory :portfolio do
    sequence(:name) { |n| "Portfolio #{n}" }
    sequence(:path) { |n| "https://example-#{n}.com" }
    tagline { "MyText" }
    active { false }

    trait :with_failed_screenshot do
      screenshot_status { :failed }
      screenshot_error { "Timeout" }
      screenshot_attempted_at { Time.current }
    end

    trait :with_successful_screenshot do
      screenshot_status { :success }
      screenshot_source { "og_image" }
      screenshot_attempted_at { Time.current }
    end
  end
end
