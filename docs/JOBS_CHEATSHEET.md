# 🚀 Jobs Quick Reference

## Most Common Commands

```bash
# Update feed and generate screenshots (PRIMARY COMMAND)
bundle exec rake jobs:update_feed

# Check everything is working
bundle exec rake jobs:diagnostic

# Check job queue status
bundle exec rake jobs:status

# Retry failed jobs
bundle exec rake jobs:retry_failed
```

**Note:** Use `rake` (not `rails`) for these custom tasks on the server!

## All Available Commands

| Command | Description |
|---------|-------------|
| `rake jobs:update_feed` | ⭐ Update feed & queue screenshots |
| `rake jobs:diagnostic` | 📊 Full system health check |
| `rake jobs:status` | 📈 Job queue status |
| `rake jobs:workers` | 👷 Check if workers are running |
| `rake jobs:failed` | ❌ Show failed jobs details |
| `rake jobs:retry_failed` | 🔄 Retry all failed jobs |
| `rake jobs:generate_screenshots` | 📸 Queue all screenshot jobs |
| `rake jobs:generate_screenshot[ID]` | 📸 Screenshot for one portfolio |
| `rake jobs:missing_screenshots` | 🔍 Find portfolios without screenshots |
| `rake jobs:run_all` | 🎯 Update feed (alias) |

**💡 Tip:** Add `bundle exec` before each command for safety: `bundle exec rake jobs:update_feed`

## Quick Troubleshooting

**Jobs not processing?**
```bash
bundle exec rake jobs:workers  # Check if workers are running
```

**Jobs failed?**
```bash
bundle exec rake jobs:failed       # See what failed
bundle exec rake jobs:retry_failed # Retry them
```

**Missing screenshots?**
```bash
bundle exec rake jobs:missing_screenshots  # See which ones are missing
bundle exec rake jobs:generate_screenshots # Generate them
```

## Example Usage

```bash
# SSH into server
ssh deploy@your-server.com

# Navigate to app directory
cd /path/to/rails_developer_portfolios

# Run the update
bundle exec rake jobs:update_feed

# Wait a minute, then check status
bundle exec rake jobs:status

# After jobs finish, verify
bundle exec rake jobs:diagnostic
```

## ⚠️ Important

- **Use `bundle exec rake`** (not `rails`) for these tasks on the server
- **Workers must be running** - Check with `bundle exec rake jobs:workers`
- **Jobs are batched** - 10 portfolios every 30 seconds (prevents overload)
- **Check Hatchbox** - If workers are down, verify Procfile and background workers are enabled

## Need More Details?

See `JOBS_REFERENCE.md` for comprehensive documentation.

