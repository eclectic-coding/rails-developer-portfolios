# Ensure a default version key exists for portfolio view fragment caching.
# Skip during asset precompilation to avoid database connection
Rails.application.config.to_prepare do
  unless ENV['SKIP_DATABASE'] == 'true'
    Rails.cache.fetch('portfolios_version') { 1 }
  end
end

