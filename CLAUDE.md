# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this app does

A Rails 8 app that fetches a list of developer portfolios from an upstream JSON feed
(`https://raw.githubusercontent.com/emmabostian/developer-portfolios/master/feed.json`), stores them in
Postgres, and displays them with search/letter-filter/infinite-scroll. Each portfolio gets a screenshot
(preferring the site's `og:image`, falling back to a Playwright-rendered capture) attached via Active
Storage. A weekly background job re-syncs the feed and refreshes screenshots. Deployed via Hatchbox.

## Commands

```bash
# Setup
bin/setup                 # bundle install, db prepare, etc.

# Run the app locally (Rails server + JS/CSS watchers via Procfile.dev)
bin/dev

# Tests
bin/rspec                                              # full suite
bin/rspec spec/services/developer_portfolios_fetcher_spec.rb  # single file
bin/rspec spec/requests/portfolios_spec.rb:42          # single example by line
bin/rspec --tag "~type:system"                         # unit tests only (what CI's `test` job runs)
bin/rspec --tag type:system                            # system tests only (what CI's `system_test` job runs)

# Lint / security (all run in CI; run before pushing)
bin/rubocop -f github
bin/brakeman --no-pager
bin/bundler-audit

# Frontend assets (jsbundling-rails / esbuild + sass, mirrors Procfile.dev)
yarn build
yarn build:css
yarn watch:css

# Portfolio data / jobs (see docs/JOBS_CHEATSHEET.md and docs/JOBS_REFERENCE.md for the full list)
bin/rails portfolios:fetch                 # sync DB from the feed only, no screenshots
bin/rails jobs:update_feed                 # sync feed AND queue screenshots for every active portfolio
bin/rails jobs:generate_screenshot[ID]     # backfill a screenshot for one portfolio
bin/rails jobs:diagnostic                  # full health report (workers, queue, portfolios)
bin/rails jobs:workers                     # is a Solid Queue worker actually running?
bin/rails jobs:status / jobs:failed / jobs:retry_failed
```

There is no `test/` directory — this app uses RSpec exclusively, configured via `.rspec` and
`spec/rails_helper.rb`/`spec/spec_helper.rb`.

## Architecture

**Single-model domain.** The whole app revolves around `Portfolio` (`app/models/portfolio.rb`): name,
path (the site URL, unique), tagline, `active` flag, and screenshot tracking fields
(`screenshot_status` enum: pending/success/failed, `screenshot_error`, `screenshot_attempted_at`,
`screenshot_source`). There is no user model, no auth — this is a read-only public directory backed by
one upstream data source.

**Sync pipeline** (`app/services/developer_portfolios_fetcher.rb`, invoked by
`FetchDeveloperPortfoliosJob`): fetches the upstream feed, matches entries to existing rows by `path`
first, then falls back to matching inactive rows by `name` (to handle a portfolio's URL changing without
creating a duplicate row), creates/updates/deactivates accordingly, and purges screenshots for
deactivated portfolios. A single malformed feed entry (bad URL, duplicate path) is skipped and logged
rather than aborting the whole sync — see `@skipped` in `SyncResult`. Every sync bumps a
`portfolios_version` cache key (read by `ApplicationHelper#portfolio_starting_letters`) used to
invalidate fragment/view caches, and emails a sync report via `AdminMailer` (recipient configured through
`admin_email` in Rails credentials).

**Screenshot pipeline**: `FetchDeveloperPortfoliosJob` enqueues one `GeneratePortfolioScreenshotJob` per
active portfolio after each sync; `RetryFailedPortfolioScreenshotsJob` runs daily to sweep anything still
`pending`/`failed`. The job itself is concurrency-capped to 3 simultaneous runs
(`limits_concurrency`) and retries `PortfolioScreenshotGenerator::CaptureError` with polynomial backoff
(3 attempts) before marking the portfolio `failed`. `PortfolioScreenshotGenerator` tries two strategies in
order:
1. `PortfolioOgImageFetcher` — scrapes the target site's `og:image`/`twitter:image` meta tag and
   downloads it directly (no browser needed). It resolves and validates every hostname (including
   through redirects) to reject loopback/private/link-local addresses — an SSRF guard, since this fetches
   arbitrary user-supplied URLs from the upstream feed. Preserve that check if you touch this file.
2. Falls back to `script/capture_portfolio_screenshot.mjs` (Node + Playwright), invoked via `system(...)`,
   writing a temp PNG under `tmp/portfolio_screenshots/` that then gets attached and removed.

Both attach the result to `Portfolio#site_screenshot` (Active Storage) and update the screenshot tracking
fields. `app/assets/images/default_portfolio_screenshot.svg` is the fallback shown when a portfolio has no
attached screenshot yet.

**Request flow**: `PortfoliosController#index` is the only real controller action — it filters
`Portfolio.active` by `starting_with(letter)` and `search(query)` scopes, paginates with Pagy (limit 12),
and responds to both `html` and `turbo_stream` (the turbo_stream format powers infinite scroll, driven by
`app/javascript/controllers/infinite_scroll_controller.js`). `Portfolios::SearchesController#index` just
redirects `GET /portfolios/searches` params back into `portfolios_path` — it exists so the search form
has a stable submit target independent of the current letter/pagination state.

**Locale switching**: `ApplicationController#switch_locale` (an `around_action`) sets `I18n.locale` per
request from the `Accept-Language` header (first matching 2-letter code against
`config.i18n.available_locales`, else falls back to `default_locale`) — it does not persist across
requests or use a URL/session locale. Supported locales: `en`, `es`, `fr`, `hi`, `ne`
(`config/application.rb`). Locale files are namespaced under `config/locales/{defaults,models,views}/`
rather than one flat file per locale — `defaults/` for app-wide/date-time strings, `models/portfolio/`
for ActiveRecord attribute/error strings, `views/{portfolios,shared}/` for view copy — with one YAML file
per locale in each directory. When adding a new user-facing string, add it to the appropriate namespace
directory in **every** locale file, not just `en`.

**Caching**: `config/initializers/portfolios_cache.rb` seeds a `portfolios_version` cache key at boot.
Rack::Attack (`config/initializers/rack_attack.rb`) throttles all requests to 300/5min per IP, sharing
Rails.cache as its store so limits apply across Puma workers.

**Job infra**: Solid Queue (`config/queue.yml`, `config/recurring.yml`) — no Redis/Sidekiq. Recurring
jobs are defined per-environment in `config/recurring.yml`. `lib/tasks/jobs.rake` and
`lib/tasks/hatchbox.rake` provide operational rake tasks for the production Hatchbox deployment (worker
health, queue status, manual backfills) — see `docs/JOBS_CHEATSHEET.md`, `docs/JOBS_REFERENCE.md`, and
`docs/DEPLOYMENT_JOBS_CHECKLIST.md` for the full reference before changing job/recurring-schedule
behavior.

## Development workflow and guardrails

- **Match CI before pushing.** `.github/workflows/ci.yml` runs unit specs, system specs, Brakeman,
  bundler-audit, and Rubocop as independent jobs against a real Postgres service — run
  `bin/rspec`, `bin/rubocop -f github`, `bin/brakeman --no-pager`, and `bin/bundler-audit` locally first
  rather than discovering failures after a push.
- **Migrations**: after adding/changing a migration, run `bin/rails db:migrate` and let the
  `annotate` task refresh the schema comment block at the top of `app/models/portfolio.rb` (development
  only, wired into `db:migrate` via `lib/tasks/auto_annotate_models.rake`) — don't hand-edit that comment
  block. Keep `db/schema.rb` committed alongside the migration.
- **`config/recurring.yml` changes**: an invalid schedule string here has previously crashed the Solid
  Queue worker in production (see `docs/DEPLOYMENT_JOBS_CHECKLIST.md`). Run `bin/validate-schedules`
  after editing it, before deploying.
- **i18n changes**: locale strings live under `config/locales/{defaults,models,views}/<namespace>/`, one
  YAML file per locale. Add/change a key in **all five** locale files (`en`, `es`, `fr`, `hi`, `ne`) in
  the same change, not just `en` — a missing key silently falls back to English in production
  (`config.i18n.fallbacks = true`) rather than failing loudly, so it's easy to ship a partial translation
  by accident.
- **`PortfolioOgImageFetcher`'s SSRF guard** (`public_host?`/`public_ip?` in
  `app/services/portfolio_og_image_fetcher.rb`) rejects loopback/private/link-local addresses on the
  original URL and every redirect hop, because the fetched URLs come from an upstream feed Claude/the app
  doesn't control. Never bypass or loosen this when touching that file.
- **Credentials**: use `bin/rails credentials:edit` to change `config/credentials.yml.enc` (e.g.
  `admin_email`); never commit `config/master.key` or paste decrypted credentials into code, commits, or
  chat.
- **Feed sync is idempotent by design** (`DeveloperPortfoliosFetcher`) — malformed entries are skipped
  and logged rather than raised. If you change matching/upsert logic, preserve that "one bad entry can't
  abort the whole sync" behavior and keep it covered by
  `spec/services/developer_portfolios_fetcher_spec.rb`.
- Only create commits/PRs/pushes when the user asks; this repo has branch protection via required CI
  checks (test, system_test, scan_ruby, lint) rather than any local pre-push hook.
- **Test-Driven Development (TDD):** write or update the corresponding spec *before or alongside* any
  Rails code change — don't land a behavior change without a spec covering it in the same change.
- **Mocking rules:** avoid heavy mocking/stubbing that lets a spec pass while production behavior
  diverges. Use `factory_bot_rails` (`spec/factories/portfolios.rb`) to build real `Portfolio` records
  through actual database interaction and model validation wherever the test needs one, and reserve
  stubbing for true external boundaries (e.g. `Net::HTTP` calls to the upstream feed or a portfolio's
  site, as the existing fetcher/screenshot specs do).
- **ActiveRecord conventions:** use strong parameters in controllers (see
  `Portfolios::SearchesController#index`'s `params.permit`). Keep business logic out of
  controllers/views — it belongs in models, concerns, or service objects (`app/services/`), following the
  existing `DeveloperPortfoliosFetcher`/`PortfolioScreenshotGenerator`/`PortfolioOgImageFetcher` split.
- **Hotwire:** prefer Turbo Frames/Streams and Stimulus controllers over vanilla JS or hand-rolled AJAX —
  follow the existing pattern of `index.turbo_stream.erb` + `infinite_scroll_controller.js` /
  `portfolio_search_controller.js` rather than introducing a new fetch-based approach.

## Notes

- Ruby 4.0.6, Rails 8.1, Postgres. Node 24.19.0 for the JS/CSS build (esbuild + sass, not
  Webpacker/importmap).
- CI (`.github/workflows/ci.yml`) runs unit specs, system specs, Brakeman, bundler-audit, and Rubocop as
  separate jobs against a real Postgres service container — match that locally before pushing.
- Rubocop uses `rubocop-rails-omakase` as its base with a handful of project overrides in `.rubocop.yml`;
  `config/`, `db/`, `lib/`, and `bin/` are excluded from linting.
- Dependabot PRs auto-merge for minor/patch updates and major dev-dependency updates
  (`.github/workflows/dependabot-auto-merge.yml`).