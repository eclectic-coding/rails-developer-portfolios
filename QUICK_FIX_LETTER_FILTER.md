# Quick Fix for Production Letter Filter Issue

## The Problem
Only "ALL" button displays after running `bin/rails portfolios:fetch` in production.

## The Solution
Run ONE of these commands in production:

### Option 1: Re-run fetch (Recommended)
```bash
bin/rails portfolios:fetch
```
This will now automatically repopulate the cache with letters.

### Option 2: Just repopulate cache
```bash
bin/rails portfolios:repopulate_cache
```

### Option 3: Clear and repopulate
```bash
REPOPULATE=true bin/rails portfolios:clear_cache
```

## Verify It Worked
```bash
bin/rails runner "puts Rails.cache.read('portfolio_starting_letters').inspect"
```

Should output:
```
["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"]
```

Then visit your portfolios page - all letter buttons should display!

## What Was Wrong
The old `portfolios:fetch` task was clearing the cache but never refilling it. This has been fixed.

## Deploy Steps
1. Deploy the updated code
2. Run one of the commands above
3. Refresh the portfolios page
4. ✅ Letters should now display!

