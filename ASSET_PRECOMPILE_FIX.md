# Hatchbox Deployment - Asset Precompile Database Error Fix

## The Problem

During Hatchbox deployment, you were getting this error:

```
rake aborted!
ActiveRecord::StatementInvalid: PG::UndefinedTable: ERROR: relation "solid_cache_entries" does not exist
LINE 10: WHERE a.attrelid = '"solid_cache_entries"'::regclass
```

**Root Cause:** When Rails runs `assets:precompile` in production mode, it loads the production environment configuration which tries to initialize:
- **Solid Cache** - requires `solid_cache_entries` table
- **Solid Queue** - requires queue tables
- **Solid Cable** - requires cable tables

These tables might not exist yet, or the database connection fails during the asset compilation phase.

## The Solution

Updated the application to use a `SKIP_DATABASE` environment variable that tells Rails to use in-memory alternatives during asset precompilation.

### Files Changed

#### 1. `config/environments/production.rb`
```ruby
# Cache store - uses memory during asset precompile
config.cache_store = ENV['SKIP_DATABASE'] == 'true' ? :memory_store : :solid_cache_store

# Queue adapter - skipped during asset precompile
unless ENV['SKIP_DATABASE'] == 'true'
  config.active_job.queue_adapter = :solid_queue
  config.solid_queue.connects_to = { database: { writing: :queue } }
end
```

**What this does:**
- When `SKIP_DATABASE=true`: Uses `:memory_store` for cache, skips Solid Queue setup
- Normal operation: Uses full database-backed Solid Cache and Solid Queue

#### 2. `config/database.yml`
```yaml
production:
  primary:
    url: <%= ENV["DATABASE_URL"] %>
  cache:
    url: <%= ENV.fetch("CACHE_DATABASE_URL") { ENV["DATABASE_URL"] } %>
  queue:
    url: <%= ENV.fetch("QUEUE_DATABASE_URL") { ENV["DATABASE_URL"] } %>
  cable:
    url: <%= ENV.fetch("CABLE_DATABASE_URL") { ENV["DATABASE_URL"] } %>
```

**What this does:** Uses Hatchbox's `DATABASE_URL` for all databases (can be separated later if needed)

## Deploy Commands for Hatchbox

In your Hatchbox app settings, update the **Deploy Commands** to:

```bash
bundle install --without development test
bundle exec rake db:migrate
bundle exec rake db:migrate:cache
bundle exec rake db:migrate:queue
bundle exec rake db:migrate:cable
SKIP_DATABASE=true bundle exec rake assets:precompile
```

**Key points:**
1. ✅ Migrations run FIRST (create all tables)
2. ✅ Assets precompile runs with `SKIP_DATABASE=true` (no DB connection needed)
3. ✅ Clean separation of concerns

## Environment Variables Required

In Hatchbox, ensure these are set:

| Variable | Value | Notes |
|----------|-------|-------|
| `DATABASE_URL` | (auto) | Hatchbox provides this automatically |

**That's it!** No other environment variables needed for basic setup.

## First-Time Deployment

If this is your very first deployment:

1. **Deploy the code** using the deploy commands above
2. **If migrations fail** (database doesn't exist), SSH to server and run:
   ```bash
   cd /home/deploy/your-app-name/current
   bundle exec rake db:create
   bundle exec rake db:setup_all
   ```
3. **Redeploy** from Hatchbox

## Testing Locally

You can verify the fix works locally:

```bash
# This should complete without database errors
RAILS_ENV=production SKIP_DATABASE=true bundle exec rake assets:precompile
```

## How It Works

### Without SKIP_DATABASE (normal operation):
```
Rails boots → Loads production.rb → Initializes Solid Cache → ✅ Uses database
                                  → Initializes Solid Queue → ✅ Uses database
                                  → Initializes Solid Cable → ✅ Uses database
```

### With SKIP_DATABASE=true (during asset precompile):
```
Rails boots → Loads production.rb → Initializes Solid Cache → ✅ Uses memory_store
                                  → Skips Solid Queue → ✅ No database needed
                                  → Solid Cable still configured but not accessed
```

## Troubleshooting

### Still getting database errors?

1. **Check your deploy commands** - Make sure `SKIP_DATABASE=true` is set on the assets:precompile line
2. **Check order** - Migrations must run before assets:precompile
3. **Clear old builds** - In Hatchbox, try a fresh deployment

### Assets not loading after deployment?

The `SKIP_DATABASE` only affects precompilation. Once deployed, your app runs normally with full database connections.

### Want to test migrations without deploying?

```bash
# Locally test all database migrations
RAILS_ENV=production bundle exec rake db:create
RAILS_ENV=production bundle exec rake db:migrate
RAILS_ENV=production bundle exec rake db:migrate:cache
RAILS_ENV=production bundle exec rake db:migrate:queue
RAILS_ENV=production bundle exec rake db:migrate:cable
```

## Summary

✅ **Problem:** Asset precompilation tried to connect to non-existent database tables
✅ **Solution:** Use `SKIP_DATABASE=true` during asset precompilation
✅ **Implementation:** Updated production config to use memory store when flag is set
✅ **Deploy commands:** Run migrations first, then precompile with flag
✅ **Result:** Clean deployments without database connection errors

Your app is now ready for Hatchbox deployment! 🚀

