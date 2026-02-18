# Ensure a default version key exists for portfolio view fragment caching.
# Skip during asset precompilation or if database tables don't exist yet
Rails.application.config.to_prepare do
  # Skip if SKIP_DATABASE is set (during asset precompilation)
  next if ENV['SKIP_DATABASE'] == 'true'

  # Skip if we're running a rake task that doesn't need database
  next if defined?(Rake) && Rake.application.top_level_tasks.any? { |t| t.include?('assets:precompile') }

  # Only fetch from cache if tables exist (migrations have been run)
  begin
    if ActiveRecord::Base.connection.data_source_exists?('solid_cache_entries')
      Rails.cache.fetch('portfolios_version') { 1 }
    end
  rescue ActiveRecord::NoDatabaseError, PG::ConnectionBad
    # Database doesn't exist yet or connection failed - skip cache initialization
    Rails.logger.info "Skipping portfolios cache initialization - database not ready"
  end
end

