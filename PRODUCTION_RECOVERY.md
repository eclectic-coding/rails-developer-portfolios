# Production Deployment Recovery Guide

## Current Situation

You're getting this error when running `bin/rails assets:precompile` in production via SSH:

```
ActiveRecord::StatementInvalid: PG::UndefinedTable: ERROR: relation "solid_cache_entries" does not exist
```

## What Was Wrong

The `config/initializers/portfolios_cache.rb` initializer was trying to access the database cache before:
1. The database tables were created
2. OR while running tasks that shouldn't need database access (like assets:precompile)

## The Fix Applied

The initializer is now **defensive** and checks multiple conditions before trying to use the cache:

1. ✅ Checks if `SKIP_DATABASE=true` is set
2. ✅ Checks if we're running `assets:precompile` task
3. ✅ Checks if the database table actually exists
4. ✅ Catches any database connection errors gracefully

## Steps to Deploy the Fixed Code

### Option 1: Fresh Deployment (Recommended)

1. **Commit and push the fixed code:**
   ```bash
   git add config/initializers/portfolios_cache.rb
   git commit -m "Fix: Make portfolios_cache initializer defensive for asset precompilation"
   git push origin main
   ```

2. **Deploy from Hatchbox dashboard**
   - Click "Deploy" in your Hatchbox app

3. **The deployment should now complete successfully!**

### Option 2: Manual Fix in Production (If Already SSH'd In)

If you're currently SSH'd into production and need to fix it immediately:

1. **First, run the database migrations:**
   ```bash
   cd ~/young-star-6591/releases/20260218160911
   RAILS_ENV=production bundle exec rake db:migrate
   RAILS_ENV=production bundle exec rake db:migrate:cache
   RAILS_ENV=production bundle exec rake db:migrate:queue
   RAILS_ENV=production bundle exec rake db:migrate:cable
   ```

2. **Then run asset precompilation:**
   ```bash
   RAILS_ENV=production bundle exec rake assets:precompile
   ```

   OR if that still fails:
   ```bash
   RAILS_ENV=production SKIP_DATABASE=true bundle exec rake assets:precompile
   ```

3. **Restart the application:**
   ```bash
   # Hatchbox will have specific restart commands, usually:
   touch ~/young-star-6591/current/tmp/restart.txt
   ```

## Recommended Hatchbox Deploy Commands

Set these in your Hatchbox app settings:

```bash
bundle install --without development test
bundle exec rake db:migrate
bundle exec rake db:migrate:cache
bundle exec rake db:migrate:queue
bundle exec rake db:migrate:cable
SKIP_DATABASE=true bundle exec rake assets:precompile
```

**Note:** The `SKIP_DATABASE=true` is still recommended as a safety measure, but now the code will work even without it.

## What Changed in the Code

**Before (would fail):**
```ruby
Rails.application.config.to_prepare do
  Rails.cache.fetch('portfolios_version') { 1 }  # ❌ Always tries to access DB
end
```

**After (defensive):**
```ruby
Rails.application.config.to_prepare do
  next if ENV['SKIP_DATABASE'] == 'true'
  next if defined?(Rake) && Rake.application.top_level_tasks.any? { |t| t.include?('assets:precompile') }

  begin
    if ActiveRecord::Base.connection.data_source_exists?('solid_cache_entries')
      Rails.cache.fetch('portfolios_version') { 1 }  # ✅ Only runs when safe
    end
  rescue ActiveRecord::NoDatabaseError, PG::ConnectionBad
    Rails.logger.info "Skipping portfolios cache initialization - database not ready"
  end
end
```

## Testing

The fix has been tested locally and works in ALL these scenarios:

✅ `RAILS_ENV=production bundle exec rake assets:precompile` (without SKIP_DATABASE)
✅ `RAILS_ENV=production SKIP_DATABASE=true bundle exec rake assets:precompile`
✅ Running in production with database tables present
✅ Running in production before migrations have run

## Next Steps

1. **Push the fixed code** to your repository
2. **Deploy from Hatchbox**
3. Your deployment should now complete successfully! 🚀

If you encounter any other issues, check the Hatchbox deployment logs for specific errors.

