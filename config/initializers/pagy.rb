# Pagy initializer file
# See https://ddnexus.github.io/pagy/docs/api/pagy

# Pagy::DEFAULT[:items] = 20        # items per page
# Pagy::DEFAULT[:size]  = [1,4,4,1] # nav bar size

# Pagy::DEFAULT[:items_param] = :items_per_page # customize items per page param
# Pagy::DEFAULT[:max_items]   = 100             # max items per page
# Pagy::DEFAULT[:cycle] = false                  # whether to cycle at the edge of pagination

# Better user experience for new/custom apps
require 'pagy/extras/bootstrap'
require 'pagy/extras/overflow'

# Default: handle empty page by reducing to last available page
Pagy::DEFAULT[:overflow] = :last_page

