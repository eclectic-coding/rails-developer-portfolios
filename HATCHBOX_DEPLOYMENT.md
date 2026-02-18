# Hatchbox Deployment Guide

## Environment Variables

In your Hatchbox app settings, ensure the following environment variable is set:

- `DATABASE_URL` - Automatically provided by Hatchbox (PostgreSQL connection string)

## Database Setup

### Important: Multiple Database Configuration

This application uses Rails multiple databases for:
- **Primary**: Main application database
- **Cache**: Solid Cache (database-backed cache)
- **Queue**: Solid Queue (background jobs)
- **Cable**: Solid Cable (WebSocket connections)

By default, all databases will use the same PostgreSQL database provided by Hatchbox via `DATABASE_URL`.

### Initial Deployment

For your first deployment, you need to create and migrate all databases. In Hatchbox:

1. **After deployment completes**, run the following command in the Hatchbox console:
   ```bash
   bundle exec rake db:create db:migrate
   ```

2. **Then migrate the additional databases**:
   ```bash
   bundle exec rake db:migrate:cache
   bundle exec rake db:migrate:queue
   bundle exec rake db:migrate:cable
   ```

   Or use the combined task:
   ```bash
   bundle exec rake db:setup_all
   ```

### Why SKIP_DATABASE is Needed

During asset precompilation, Rails loads the production environment which tries to:
- Initialize Solid Cache (needs `solid_cache_entries` table)
- Initialize Solid Queue (needs queue tables)
- Initialize Solid Cable (needs cable tables)

The `SKIP_DATABASE=true` environment variable tells Rails to use in-memory alternatives during asset precompilation, avoiding database connections entirely.

### Deployment Process Order

The deployment should follow this order:
1. ✅ Code deployment
2. ✅ Bundle install
3. ✅ Database migrations (creates tables)
4. ✅ Assets precompile (with SKIP_DATABASE=true)
5. ✅ Server restart


## What Changed

### 1. Database Configuration (`config/database.yml`)
- Updated production config to use `DATABASE_URL` environment variable
- All secondary databases (cache, queue, cable) fall back to `DATABASE_URL`

### 2. Production Environment (`config/environments/production.rb`)
- Added conditional cache store configuration (uses memory store during asset precompile)
- Added conditional Solid Queue configuration (skips during asset precompile)
- This prevents database connection errors during `assets:precompile`

### 3. Custom Rake Task (`lib/tasks/hatchbox.rake`)
- Added `db:setup_all` task for convenient database setup
- Migrates all databases (primary, cache, queue, cable) in one command

## Troubleshooting

### Error: "relation does not exist" during asset precompile
- The code now conditionally disables database-backed features during asset precompilation
- Ensure migrations run BEFORE assets:precompile in your deploy commands

### Multiple Database Migrations
If you need to run migrations on all databases manually:
```bash
bundle exec rake db:migrate          # Primary
bundle exec rake db:migrate:cache    # Cache
bundle exec rake db:migrate:queue    # Queue
bundle exec rake db:migrate:cable    # Cable
```

### Database Status Check
```bash
bundle exec rails db:prepare
```

## Optional: Separate Databases

If you want to use separate PostgreSQL databases for cache/queue/cable in the future, add these environment variables in Hatchbox:

- `CACHE_DATABASE_URL` - Separate cache database
- `QUEUE_DATABASE_URL` - Separate queue database
- `CABLE_DATABASE_URL` - Separate cable database

If these are not set, everything will use the main `DATABASE_URL`.

