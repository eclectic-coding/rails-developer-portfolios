group :development, :test do
  gem 'rspec-rails', '~> 8.0.0'
  gem "factory_bot_rails"
  gem "turbo_rspec", require: false
  gem "stimulus_spec", require: false
end

group :development do
  gem "fuubar"
end

group :test do
  gem "webmock"
  gem 'simplecov', require: false
  gem "capybara"
  gem "selenium-webdriver"
end
