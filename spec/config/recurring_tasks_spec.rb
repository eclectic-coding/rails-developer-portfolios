require 'rails_helper'
require 'fugit'

RSpec.describe 'Recurring Tasks Configuration' do
  describe 'config/recurring.yml' do
    let(:config_file) { Rails.root.join('config', 'recurring.yml') }
    let(:config) { YAML.load_file(config_file) }

    it 'exists' do
      expect(File.exist?(config_file)).to be true
    end

    describe 'production environment' do
      let(:production_tasks) { config['production'] || {} }

      it 'has tasks defined' do
        expect(production_tasks).not_to be_empty
      end

      it 'all tasks have valid Fugit schedules' do
        invalid_tasks = []

        production_tasks.each do |task_key, task_config|
          schedule = task_config['schedule']

          if schedule.nil?
            invalid_tasks << { task: task_key, reason: 'Missing schedule' }
            next
          end

          parsed = Fugit.parse(schedule)
          if parsed.nil?
            invalid_tasks << { task: task_key, schedule: schedule, reason: 'Invalid Fugit syntax' }
          end
        end

        if invalid_tasks.any?
          error_message = "Invalid recurring task schedules found:\n"
          invalid_tasks.each do |error|
            error_message += "  - #{error[:task]}: #{error[:reason]}"
            error_message += " (#{error[:schedule]})" if error[:schedule]
            error_message += "\n"
          end
          error_message += "\nValid formats: 'every Monday at 2am', 'every day at 5pm', 'every hour', '0 2 * * 1'"

          fail(error_message)
        end
      end

      it 'all tasks have either a class or command defined' do
        production_tasks.each do |task_key, task_config|
          expect(task_config['class'] || task_config['command']).not_to be_nil,
            "Task '#{task_key}' must have either 'class' or 'command' defined"
        end
      end

      describe 'clear_solid_queue_finished_jobs' do
        let(:task) { production_tasks['clear_solid_queue_finished_jobs'] }

        it 'is defined' do
          expect(task).not_to be_nil
        end

        it 'has a valid schedule' do
          expect(Fugit.parse(task['schedule'])).not_to be_nil
        end

        it 'has a command defined' do
          expect(task['command']).to include('SolidQueue::Job.clear_finished_in_batches')
        end
      end

      describe 'fetch_developer_portfolios' do
        let(:task) { production_tasks['fetch_developer_portfolios'] }

        it 'is defined' do
          expect(task).not_to be_nil
        end

        it 'has a valid schedule' do
          parsed = Fugit.parse(task['schedule'])
          expect(parsed).not_to be_nil,
            "Schedule '#{task['schedule']}' is not valid Fugit syntax"
        end

        it 'references the correct job class' do
          expect(task['class']).to eq('FetchDeveloperPortfoliosJob')
        end

        it 'job class exists and is valid' do
          expect { FetchDeveloperPortfoliosJob }.not_to raise_error
          expect(FetchDeveloperPortfoliosJob).to be < ApplicationJob
        end
      end
    end

    describe 'development environment' do
      let(:development_tasks) { config['development'] || {} }

      it 'all tasks have valid Fugit schedules' do
        development_tasks.each do |task_key, task_config|
          schedule = task_config['schedule']
          next if schedule.nil?

          parsed = Fugit.parse(schedule)
          expect(parsed).not_to be_nil,
            "Development task '#{task_key}' has invalid schedule: '#{schedule}'"
        end
      end
    end
  end

  describe 'Fugit schedule parsing examples' do
    # Document valid schedule formats with examples
    context 'valid schedules' do
      valid_schedules = [
        'every Monday at 2am',
        'every day at 5pm',
        'every hour',
        'every 15 minutes',
        'at 5am every day',
        '0 2 * * 1',  # cron format
        'every hour at minute 12',
        'every Tuesday at 3pm'
      ]

      valid_schedules.each do |schedule|
        it "parses '#{schedule}' successfully" do
          expect(Fugit.parse(schedule)).not_to be_nil
        end
      end
    end

    context 'invalid schedules' do
      invalid_schedules = [
        'every week on Monday at 2am',  # The bug we had!
        'weekly at Monday 2am',
        'Monday at 2am every week',
        'invalid schedule',
        ''
      ]

      invalid_schedules.each do |schedule|
        it "rejects '#{schedule}' (not Fugit::Cron)" do
          parsed = Fugit.parse(schedule)
          expect(parsed).not_to be_instance_of(Fugit::Cron),
            "Schedule '#{schedule}' should NOT be valid (got #{parsed.class.name})"
        end
      end
    end
  end

  describe 'Solid Queue integration' do
    it 'can load recurring tasks without errors' do
      # This simulates what Solid Queue does on startup
      # It validates that schedules are Fugit::Cron instances
      expect {
        config = YAML.load_file(Rails.root.join('config', 'recurring.yml'))
        tasks = config[Rails.env] || {}

        tasks.each do |key, task_config|
          schedule = task_config['schedule']
          parsed = Fugit.parse(schedule)

          # Solid Queue requires EXACTLY Fugit::Cron (see RecurringTask#supported_schedule)
          unless parsed.instance_of?(Fugit::Cron)
            raise "Invalid recurring tasks:\n- #{key}: Schedule is not a supported recurring schedule"
          end
        end
      }.not_to raise_error
    end
  end
end
