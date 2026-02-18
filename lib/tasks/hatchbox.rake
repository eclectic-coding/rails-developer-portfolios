# frozen_string_literal: true

namespace :db do
  desc "Setup all databases for deployment (including Solid Cache/Queue/Cable)"
  task setup_all: :environment do
    puts "Setting up all databases..."

    # Create database if it doesn't exist
    Rake::Task["db:create"].invoke rescue nil

    # Migrate primary database first
    puts "Migrating primary database..."
    Rake::Task["db:migrate"].invoke

    # Load Solid gem schemas
    Rake::Task["db:load_solid_schemas"].invoke

    puts "All databases setup complete!"
  end

  desc "Load Solid gem schemas (cache, queue, cable) into database"
  task load_solid_schemas: :environment do
    puts "Loading Solid gem schemas into database..."

    %w[cache queue cable].each do |schema_name|
      schema_file = Rails.root.join("db", "#{schema_name}_schema.rb")

      if File.exist?(schema_file)
        puts "  Loading #{schema_name} schema..."
        begin
          # Load and execute the schema file content
          schema_content = File.read(schema_file)
          ActiveRecord::Base.connection.instance_eval(schema_content)
          puts "    ✓ #{schema_name} schema loaded successfully"
        rescue => e
          puts "    ✗ Error loading #{schema_name} schema: #{e.message}"
          puts "    #{e.backtrace.first}"
        end
      else
        puts "  ⚠ Schema file not found: #{schema_file}"
      end
    end

    puts "Solid schemas loading complete!"
  end
end

