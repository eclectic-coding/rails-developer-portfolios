# frozen_string_literal: true

namespace :db do
  desc "Setup all databases for deployment"
  task setup_all: :environment do
    puts "Setting up all databases..."

    # Create all databases
    Rake::Task["db:create"].invoke

    # Migrate primary database
    puts "Migrating primary database..."
    Rake::Task["db:migrate"].invoke

    # Migrate cache database if configured
    if ActiveRecord::Base.configurations.configs_for(env_name: Rails.env).any? { |c| c.name == "cache" }
      puts "Migrating cache database..."
      Rake::Task["db:migrate:cache"].invoke
    end

    # Migrate queue database if configured
    if ActiveRecord::Base.configurations.configs_for(env_name: Rails.env).any? { |c| c.name == "queue" }
      puts "Migrating queue database..."
      Rake::Task["db:migrate:queue"].invoke
    end

    # Migrate cable database if configured
    if ActiveRecord::Base.configurations.configs_for(env_name: Rails.env).any? { |c| c.name == "cable" }
      puts "Migrating cable database..."
      Rake::Task["db:migrate:cable"].invoke
    end

    puts "All databases setup complete!"
  end
end

