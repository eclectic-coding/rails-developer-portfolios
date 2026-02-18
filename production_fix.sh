#!/bin/bash
# Production Emergency Fix Script for Hatchbox
# Run this script on your production server to fix the 500 errors

set -e  # Exit on error

echo "=========================================="
echo "Production Fix - Loading Solid Schemas"
echo "=========================================="
echo ""

# Navigate to current release directory
cd ~/young-star-6591/current

echo "Step 1: Loading Solid Cache schema..."
RAILS_ENV=production bundle exec rails runner "
  schema_file = Rails.root.join('db/cache_schema.rb')
  if File.exist?(schema_file)
    ActiveRecord::Base.connection.instance_eval(File.read(schema_file))
    puts '  ✓ Cache schema loaded'
  else
    puts '  ⚠ Cache schema file not found'
  end
"

echo ""
echo "Step 2: Loading Solid Queue schema..."
RAILS_ENV=production bundle exec rails runner "
  schema_file = Rails.root.join('db/queue_schema.rb')
  if File.exist?(schema_file)
    ActiveRecord::Base.connection.instance_eval(File.read(schema_file))
    puts '  ✓ Queue schema loaded'
  else
    puts '  ⚠ Queue schema file not found'
  end
"

echo ""
echo "Step 3: Loading Solid Cable schema..."
RAILS_ENV=production bundle exec rails runner "
  schema_file = Rails.root.join('db/cable_schema.rb')
  if File.exist?(schema_file)
    ActiveRecord::Base.connection.instance_eval(File.read(schema_file))
    puts '  ✓ Cable schema loaded'
  else
    puts '  ⚠ Cable schema file not found'
  end
"

echo ""
echo "Step 4: Verifying tables were created..."
TABLE_COUNT=$(RAILS_ENV=production bundle exec rails runner "puts ActiveRecord::Base.connection.tables.grep(/solid/).count")
echo "  Found $TABLE_COUNT Solid tables (expected: 13)"

echo ""
echo "Step 5: Restarting the application..."
touch tmp/restart.txt
echo "  ✓ Application restart triggered"

echo ""
echo "=========================================="
echo "✓ Fix Complete!"
echo "=========================================="
echo ""
echo "Your application should now be working."
echo "Visit your app URL to verify."
echo ""

