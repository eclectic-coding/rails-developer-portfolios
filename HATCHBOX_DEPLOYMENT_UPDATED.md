# Hatchbox Deployment Guide - UPDATED

## Environment Variables

In your Hatchbox app settings, ensure the following environment variable is set:

- `DATABASE_URL` - Automatically provided by Hatchbox (PostgreSQL connection string)

## Deploy Commands (IMPORTANT - Use These Exact Commands)

In your Hatchbox app settings, set the **Deploy Commands** to:

```bash
bundle install --without development test
bundle exec rake db:migrate
bundle exec rake db:load_solid_schemas
SKIP_DATABASE=true bundle exec rake assets:precompile
```

## What Each Command Does

1. **`bundle install`** - Installs Ruby gems
2. **`bundle exec rake db:migrate`** - Runs primary database migrations
3. **`bundle exec rake db:load_solid_schemas`** - **CRITICAL**: Creates Solid Cache/Queue/Cable tables
4. **`SKIP_DATABASE=true bundle exec rake assets:precompile`** - Compiles assets without database connection

## Why `db:load_solid_schemas` is Required

Rails 8's Solid gems use **schema files** instead of traditional migrations:
- `db/cache_schema.rb` - Defines `solid_cache_entries` table
- `db/queue_schema.rb` - Defines `solid_queue_*` tables (11 tables)
- `db/cable_schema.rb` - Defines `solid_cable_messages` table

The custom `db:load_solid_schemas` rake task loads these schemas into your database.

**Without this step, you'll get 500 errors:**
```
PG::UndefinedTable: ERROR: relation "solid_cache_entries" does not exist
```

## Database Configuration

This application uses Rails multiple databases:
- **Primary**: Main application database (portfolios, etc.)
- **Cache**: Solid Cache (database-backed cache)
- **Queue**: Solid Queue (background jobs)
- **Cable**: Solid Cable (WebSocket connections)

By default, **all databases use the same PostgreSQL database** provided by Hatchbox via `DATABASE_URL`.

## First-Time Deployment Steps

### 1. Deploy from Hatchbox

Click "Deploy" in your Hatchbox dashboard with the deploy commands above.

### 2. If You're Already Deployed and Getting 500 Errors

SSH into your server and run:

```bash
cd ~/your-app-path/current
RAILS_ENV=production bundle exec rake db:load_solid_schemas
```

Then restart your app:
```bash
touch tmp/restart.txt
```

### 3. Verify Tables Were Created

```bash
RAILS_ENV=production bundle exec rails runner "puts ActiveRecord::Base.connection.tables.grep(/solid/).count"
# Should output: 13 (1 cache + 11 queue + 1 cable)
```

## Complete Setup Task

Alternatively, you can use the comprehensive setup task:

```bash
bundle exec rake db:setup_all
```

This will:
1. Create the database (if needed)
2. Run migrations
3. Load all Solid schemas

## What Changed in Your Code

### 1. `config/database.yml`
- Updated to use Hatchbox's `DATABASE_URL`
- All secondary databases fall back to `DATABASE_URL`

### 2. `config/environments/production.rb`
- Conditional cache store (memory during asset precompile)
- Conditional Solid Queue setup

### 3. `config/initializers/portfolios_cache.rb`
- Defensive cache initialization
- Checks if tables exist before accessing cache

### 4. `lib/tasks/hatchbox.rake`
- **NEW**: `db:load_solid_schemas` task
- **NEW**: `db:setup_all` task for complete setup

## Troubleshooting

### Error: "relation solid_cache_entries does not exist"

**Solution**: Run the solid schemas loading task:
```bash
RAILS_ENV=production bundle exec rake db:load_solid_schemas
```

### Assets Precompilation Fails

**Solution**: Make sure `SKIP_DATABASE=true` is set:
```bash
SKIP_DATABASE=true bundle exec rake assets:precompile
```

### 500 Errors After Deployment

1. Check if Solid tables exist:
   ```bash
   RAILS_ENV=production bundle exec rails runner "puts ActiveRecord::Base.connection.tables.grep(/solid/).inspect"
   ```

2. If tables are missing, load the schemas:
   ```bash
   RAILS_ENV=production bundle exec rake db:load_solid_schemas
   ```

3. Restart the app:
   ```bash
   touch tmp/restart.txt
   ```

## Summary

✅ **Updated deploy commands** to include `db:load_solid_schemas`
✅ **Created custom rake task** to load Solid gem schemas
✅ **Defensive initializer** prevents cache errors during boot
✅ **All Solid tables** created in single database via schema files

Your app should now deploy successfully to Hatchbox! 🚀

