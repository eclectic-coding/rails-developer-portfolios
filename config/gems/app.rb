gem "annotate"
gem "cssbundling-rails"
gem "pagy"
gem "inline_svg"
gem "name_of_person"
# gem "strong_migrations"

group :development, :test do
  gem "erb_lint"
  gem "faker"
end

group :development do
  gem "bundle-audit", require: false
  gem "hotwire-spark"
  # gem "bullet"
  gem "letter_opener_web"
  gem "rails-erd"
end
