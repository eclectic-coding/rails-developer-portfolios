# Why Tests Didn't Catch the Invalid Schedule Bug

## The Problem

Your Solid Queue workers were crashing with:
```
Invalid recurring tasks:
- fetch_developer_portfolios: Schedule is not a supported recurring schedule
```

The schedule `every week on Monday at 2am` **looked valid** but wasn't.

## Why Tests Didn't Catch It

### 1. No Configuration Tests
**There were NO tests for `config/recurring.yml`** at all. The test suite included:
- Job behavior tests (✅ `spec/jobs/*_spec.rb`)
- Model tests (✅ `spec/models/*_spec.rb`)
- Request tests (✅ `spec/requests/*_spec.rb`)
- But NO config validation tests (❌)

### 2. The Bug is Subtle

The schedule `every week on Monday at 2am` **IS valid Fugit syntax!**

```ruby
Fugit.parse("every week on Monday at 2am")
# => #<EtOrbi::EoTime> (parses successfully!)
```

But Solid Queue requires **specifically** `Fugit::Cron`, not just any Fugit parse result:

```ruby
# What Solid Queue checks (from RecurringTask model):
def supported_schedule
  unless parsed_schedule.instance_of?(Fugit::Cron)
    errors.add :schedule, :unsupported
  end
end
```

### 3. The Difference

```ruby
# ❌ INVALID - Parses as EtOrbi::EoTime (a timestamp)
Fugit.parse("every week on Monday at 2am")
# => #<EtOrbi::EoTime> ❌ NOT Fugit::Cron

# ✅ VALID - Parses as Fugit::Cron (recurring schedule)
Fugit.parse("every Monday at 2am")
# => #<Fugit::Cron> ✅ Correct!
```

The phrase "every week on" makes Fugit interpret it as a **one-time timestamp** ("next Monday at 2am"), not a **recurring schedule**.

## What We've Added

### New Test File: `spec/config/recurring_tasks_spec.rb`

This test file now validates:

1. **Schedule validity** - All schedules must be `Fugit::Cron`
2. **Job classes exist** - Referenced classes must be defined
3. **Required fields** - Each task has class/command and schedule
4. **Examples** - Documents valid vs invalid schedule formats
5. **Integration test** - Simulates Solid Queue's startup validation

### Key Tests

```ruby
it 'all tasks have valid Fugit schedules' do
  production_tasks.each do |task_key, task_config|
    parsed = Fugit.parse(task_config['schedule'])

    # This is the critical check Solid Queue does!
    unless parsed.instance_of?(Fugit::Cron)
      fail "Task '#{task_key}' schedule is not Fugit::Cron!"
    end
  end
end
```

### Example Tests

The spec includes **explicit examples** of what works and what doesn't:

```ruby
# ✅ Valid (all become Fugit::Cron)
'every Monday at 2am'
'every day at 5pm'
'every hour'
'0 2 * * 1' # cron format

# ❌ Invalid (become EtOrbi::EoTime or other types)
'every week on Monday at 2am' # THE BUG!
'weekly at Monday 2am'
'Monday at 2am every week'
```

## Running the Tests

```bash
# Run config tests
bundle exec rspec spec/config/recurring_tasks_spec.rb

# Or run all tests
bundle exec rspec
```

## How This Prevents Future Issues

### 1. Catches Invalid Schedules Early
Tests run on every commit/PR, catching bad schedules before deployment.

### 2. Documents Valid Formats
The tests serve as documentation showing what schedule formats work.

### 3. Validates Like Production
The integration test simulates exactly what Solid Queue does on startup.

### 4. Fails Fast
If someone adds an invalid schedule, tests fail immediately with a clear message:

```
Failure: Invalid recurring task schedules found:
  - my_task: Not a Fugit::Cron (got EtOrbi::EoTime)

Valid formats: 'every Monday at 2am', 'every day at 5pm', 'every hour'
Solid Queue requires Fugit::Cron instances only!
```

## Adding to CI

Make sure your CI runs these tests. In your CI configuration:

```yaml
# .github/workflows/ci.yml or similar
- name: Run tests
  run: bundle exec rspec
```

The config tests are now part of the default test suite.

## Validation Tool

You can also validate schedules manually:

```bash
# Validate all schedules in recurring.yml
bin/validate-schedules
```

This provides the same check without running the full test suite.

## Lessons Learned

### 1. Test Configuration, Not Just Code
Configuration files can have bugs too! Test them.

### 2. Understand Your Dependencies
Solid Queue's requirement for `Fugit::Cron` specifically (not just any Fugit type) was subtle but critical.

### 3. Test Integration Points
The test suite should validate how your app integrates with libraries, not just your own code.

### 4. Make Tests Explicit
Include example-based tests that show exactly what works and what doesn't.

## Similar Issues to Watch For

Other configuration that should be tested:
- Database connection configs
- Redis/Cache configs
- Email delivery settings
- S3/Storage credentials format
- API endpoint URLs
- Feature flags
- Scheduled task definitions

Consider adding config tests for any critical YAML/environment configuration your app relies on!

---

**Bottom line:** We had job tests, but no config tests. Now we have both! 🎉

