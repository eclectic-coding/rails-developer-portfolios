# Letter Filter Fix

## Problem
In production, only the "All" button was displaying in the portfolio letter filters. The individual letter buttons (A, B, C, etc.) were not appearing, even after running `bin/rails portfolios:fetch`.

## Root Cause
The `portfolio_starting_letters` helper method caches its results using `Rails.cache.fetch('portfolio_starting_letters')`. In production, when:

1. The cache was initially populated (likely empty or with old data)
2. Then portfolios were fetched with `bin/rails portfolios:fetch`
3. The cache was never cleared/updated

The stale cached value persisted, causing the filters to not display even though portfolios existed in the database.

## Solution
Modified the `portfolios:fetch` rake task to automatically clear the `portfolio_starting_letters` cache after successfully syncing portfolios. This ensures the letter filters will be regenerated with the current data on the next page load.

### Changes Made
1. **lib/tasks/portfolios.rake**: Added `Rails.cache.delete('portfolio_starting_letters')` after successful portfolio sync
2. **lib/tasks/portfolios.rake**: Updated the `clear_cache` task to actually clear the cache instead of being a no-op

## To Fix in Production

### Option 1: Re-run the fetch task (Recommended)
Since the rake task now clears the cache automatically, just re-run:
```bash
bin/rails portfolios:fetch
```

### Option 2: Manually clear the cache
You can also manually clear the cache:
```bash
bin/rails portfolios:clear_cache
```

After running either command, refresh your browser and the letter filter buttons should appear.

## Prevention
The fix ensures this won't happen again - every time `portfolios:fetch` is run, the cache will be automatically cleared so the filters stay in sync with the database.

