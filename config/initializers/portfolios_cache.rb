# Ensure a default version key exists for portfolio view fragment caching.
Rails.application.config.to_prepare do
  Rails.cache.fetch('portfolios_version') { 1 }
end

