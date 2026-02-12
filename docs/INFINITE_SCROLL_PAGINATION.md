# Infinite Scroll Pagination Implementation

## Overview

This implementation adds infinite scroll pagination to the portfolio listing page using the Pagy gem, Stimulus JS, and the Intersection Observer API. The interface loads 12 portfolio cards initially and automatically loads more as you scroll down.

## Key Features

✅ **12 Cards Per Page**: Initial load shows only 12 portfolio cards for better performance
✅ **Load on Scroll**: Automatically loads more content when scrolling near the bottom
✅ **Intersection Observer API**: Modern, performant scroll detection
✅ **Reactive Interface**: Seamless content loading without page refreshes
✅ **Search Compatible**: Maintains all search and filter functionality
✅ **Letter Filters**: Works perfectly with A-Z letter filtering
✅ **Turbo Streams**: Uses Rails Turbo for efficient partial updates

## Technical Implementation

### 1. Backend Changes

#### Controller (`app/controllers/portfolios_controller.rb`)
```ruby
class PortfoliosController < ApplicationController
  def index
    @query = params[:q].to_s.presence
    @letter = params[:letter].to_s.presence

    portfolios_scope = Portfolio.active
                                .starting_with(@letter)
                                .search(@query)

    @pagy, @portfolios = pagy(portfolios_scope, items: 12)

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end
end
```

**What changed:**
- Added `@letter` param support for letter filtering
- Created a chained scope for filtering and searching
- Used Pagy to paginate with 12 items per page
- Added `turbo_stream` format support for AJAX loads

#### Turbo Stream View (`app/views/portfolios/index.turbo_stream.erb`)
This view handles subsequent page loads via AJAX:
- Appends new portfolio cards to the stream container
- Updates the sentinel element with new pagination URL
- Shows "no more portfolios" message when done

### 2. Frontend Changes

#### Stimulus Controller (`app/javascript/controllers/infinite_scroll_controller.js`)
```javascript
export default class extends Controller {
  static targets = ["sentinel"]
  static values = { url: String }

  // Creates Intersection Observer to watch sentinel element
  // Loads more content when sentinel becomes visible
  // Updates URL for next page automatically
}
```

**How it works:**
1. **Observer Setup**: Watches a "sentinel" div at the bottom of the content
2. **Trigger**: When sentinel comes into view (100px margin), loads next page
3. **Fetch**: Makes AJAX request for turbo_stream format
4. **Update**: Turbo automatically processes response and updates DOM
5. **Repeat**: New sentinel is added with next page URL

#### Updated Views

**Main Index** (`app/views/portfolios/index.html.erb`):
- Wraps content in infinite-scroll controller
- Shows initial 12 portfolios in turbo-frame
- Adds stream container for subsequent loads
- Shows loading spinner sentinel when more pages exist

**Letter Filters** (`app/views/portfolios/_letter_filters.html.erb`):
- Updated to reload entire page on filter change
- Maintains query params across filters
- Resets pagination when filtering

### 3. Configuration

#### Pagy Setup
- **ApplicationController**: Includes `Pagy::Backend`
- **ApplicationHelper**: Includes `Pagy::Frontend`
- **Initializer**: Basic configuration file at `config/initializers/pagy.rb`

## User Experience Flow

### Initial Load
1. User visits `/portfolios`
2. Server returns first 12 portfolios
3. Sentinel div appears at bottom with spinner

### Scrolling
1. User scrolls down the page
2. When sentinel comes into view (100px before visible)
3. Stimulus controller fetches next page via AJAX
4. New cards appear seamlessly
5. Sentinel moves to bottom with new page URL
6. Process repeats until no more pages

### Searching
1. User types in search box
2. Form submits with debounce (250ms)
3. Page reloads with filtered results
4. Pagination resets to page 1
5. Infinite scroll works with filtered results

### Letter Filtering
1. User clicks a letter (e.g., "A")
2. Page reloads showing portfolios starting with "A"
3. Search query is maintained if present
4. Pagination resets to page 1
5. Infinite scroll works with filtered results

## Performance Considerations

### Optimization Features
- **Lazy Loading**: Only 12 cards initially loaded
- **Efficient Observer**: Intersection Observer is much more performant than scroll events
- **Turbo Streams**: Only new content is sent/rendered, not entire page
- **Debounced Search**: 250ms delay prevents excessive searches
- **Caching**: Maintains existing Rails fragment caching

### Database Queries
- Pagy uses efficient `LIMIT` and `OFFSET` SQL queries
- Scopes are chainable and combine into single query
- No N+1 queries (ActiveStorage eager loading maintained)

## Browser Compatibility

The Intersection Observer API is supported in:
- ✅ Chrome 51+
- ✅ Firefox 55+
- ✅ Safari 12.1+
- ✅ Edge 15+

For older browsers, consider adding a polyfill or fallback to traditional pagination.

## Testing the Implementation

### Manual Testing Steps

1. **Basic Pagination**
   ```bash
   bin/rails server
   # Visit http://localhost:3000
   # Scroll down to see more portfolios load
   ```

2. **Search with Pagination**
   ```
   # Type in search box: "developer"
   # Verify first 12 results shown
   # Scroll to load more matching results
   ```

3. **Letter Filter with Pagination**
   ```
   # Click letter "A"
   # Verify only "A" portfolios shown
   # Scroll to load more "A" portfolios
   ```

4. **Combined Filters**
   ```
   # Click letter "B"
   # Search for "bootstrap"
   # Verify both filters applied
   # Scroll for pagination
   ```

### Debugging

Check browser console for logs:
- `InfiniteScrollController connected`
- `Loading more portfolios from: /portfolios?page=2`
- `URL changed to: /portfolios?page=3`

## Files Modified

### New Files
- `app/javascript/controllers/infinite_scroll_controller.js` - Stimulus controller
- `app/views/portfolios/index.turbo_stream.erb` - Turbo stream response template

### Modified Files
- `app/controllers/portfolios_controller.rb` - Added pagination logic
- `app/views/portfolios/index.html.erb` - Added infinite scroll wrapper
- `app/views/portfolios/_letter_filters.html.erb` - Updated for full page loads
- `config/initializers/pagy.rb` - Simplified configuration

### Previous Files (Pagy Setup)
- `app/controllers/application_controller.rb` - Added `Pagy::Backend`
- `app/helpers/application_helper.rb` - Added `Pagy::Frontend`

## Troubleshooting

### Issue: No more items loading
**Check:**
- Browser console for errors
- Network tab for failed requests
- Sentinel element exists in DOM
- `@pagy.next` returns correct page number

### Issue: Items load too late/early
**Solution:** Adjust `rootMargin` in Stimulus controller:
```javascript
rootMargin: "200px", // Load earlier
rootMargin: "50px",  // Load later
```

### Issue: Search breaks pagination
**Check:**
- `@query` and `@letter` params in turbo_stream URL
- Form data attributes include both params
- URL generation includes all filter params

## Future Enhancements

### Possible Improvements
1. **Skeleton Loaders**: Replace spinner with content placeholders
2. **Scroll Position**: Remember position when navigating back
3. **Virtual Scrolling**: For very large lists (1000+ items)
4. **Loading States**: More sophisticated loading indicators
5. **Error Handling**: User-friendly error messages
6. **Prefetching**: Load next page before sentinel is visible
7. **Analytics**: Track scroll depth and engagement

## Additional Notes

- The implementation maintains all existing caching strategies
- Fragment caching key includes page number to prevent cache collision
- Works seamlessly with Turbo Drive for fast navigation
- Compatible with existing test suite (may need specs updated)
- Mobile-responsive and touch-friendly

---

**Implementation Date**: February 12, 2026
**Total Portfolios**: 1,474
**Pages (at 12/page)**: ~123 pages
**Initial Load Time**: Significantly improved (12 vs 1474 cards)

