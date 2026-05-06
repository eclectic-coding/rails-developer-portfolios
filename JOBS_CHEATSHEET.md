# 🚀 Jobs Quick Reference

## Most Common Commands

```bash
# Update feed and generate screenshots (PRIMARY COMMAND)
rails jobs:update_feed

# Check everything is working
rails jobs:diagnostic

# Check job queue status
rails jobs:status

# Retry failed jobs
rails jobs:retry_failed
```

## All Available Commands

| Command | Description |
|---------|-------------|
| `rails jobs:update_feed` | ⭐ Update feed & queue screenshots |
| `rails jobs:diagnostic` | 📊 Full system health check |
| `rails jobs:status` | 📈 Job queue status |
| `rails jobs:workers` | 👷 Check if workers are running |
| `rails jobs:failed` | ❌ Show failed jobs details |
| `rails jobs:retry_failed` | 🔄 Retry all failed jobs |
| `rails jobs:generate_screenshots` | 📸 Queue all screenshot jobs |
| `rails jobs:generate_screenshot[ID]` | 📸 Screenshot for one portfolio |
| `rails jobs:missing_screenshots` | 🔍 Find portfolios without screenshots |
| `rails jobs:run_all` | 🎯 Update feed (alias) |

## Quick Troubleshooting

**Jobs not processing?**
```bash
rails jobs:workers  # Check if workers are running
```

**Jobs failed?**
```bash
rails jobs:failed       # See what failed
rails jobs:retry_failed # Retry them
```

**Missing screenshots?**
```bash
rails jobs:missing_screenshots  # See which ones are missing
rails jobs:generate_screenshots # Generate them
```

## Example Usage

```bash
# SSH into server
ssh deploy@your-server.com

# Navigate to app directory
cd /path/to/rails_developer_portfolios

# Run the update
rails jobs:update_feed

# Wait a minute, then check status
rails jobs:status

# After jobs finish, verify
rails jobs:diagnostic
```

## ⚠️ Important

- **Workers must be running** - Check with `rails jobs:workers`
- **Jobs are batched** - 10 portfolios every 30 seconds (prevents overload)
- **Check Hatchbox** - If workers are down, verify Procfile and background workers are enabled

## Need More Details?

See `JOBS_REFERENCE.md` for comprehensive documentation.

