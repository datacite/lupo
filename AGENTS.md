# AGENTS.md

## Cursor Cloud specific instructions

This repo is the DataCite REST API ("Lupo"), a Ruby on Rails 8.1 API-only app
(Ruby 4.0.1, Bundler). Upstream development uses Docker Compose + Passenger (see
`README.md`), but in Cursor Cloud it is set up to run **natively, without Docker**:
Ruby 4.0.1 is installed via `rbenv`, and MySQL 8.0, Memcached, and OpenSearch 2
run as local services on `localhost`.

### Backing services (start these at the start of a session — not auto-started)

- MySQL: `sudo service mysql start` — `127.0.0.1:3306`, user `root`, empty password.
- Memcached: `sudo service memcached start` — `127.0.0.1:11211`.
- OpenSearch 2 (single-node, security plugin disabled): first set the kernel limit
  once per boot with `sudo sysctl -w vm.max_map_count=262144`, then start it in a
  tmux session: `cd ~/opensearch && OPENSEARCH_JAVA_OPTS="-Xms1g -Xmx1g" ./bin/opensearch`.
  Verify with `curl -s localhost:9200`.

The MySQL data (databases `datacite` and `datacite_test`) and the OpenSearch data
persist in the VM snapshot, so you normally do not need to recreate them. If you do:
`bundle exec rake db:setup RAILS_ENV=development`, `... db:create db:schema:load RAILS_ENV=test`,
and `bundle exec rake elasticsearch:create_all_indexes RAILS_ENV=development`.

### Environment

- `rbenv` is initialized from `~/.bashrc`, so interactive shells get Ruby 4.0.1.
  In non-interactive contexts, call the shims directly (e.g. `~/.rbenv/shims/bundle`).
- A git-ignored `.env` (created during setup) overrides the Docker service
  hostnames (`mysql`/`elasticsearch`/`memcached`) with `localhost`. It also sets
  `ELASTIC_PASSWORD` (the ES client hardcodes user `elastic`, so a non-nil password
  is required even though OpenSearch security is disabled) and the RSA `JWT_PRIVATE_KEY`
  / `JWT_PUBLIC_KEY` (the `spec/fixtures/certs` keys) so auth tokens work in dev.
  If `.env` is missing, recreate those overrides.

### Lint / test / run

- Lint: `bundle exec rubocop --parallel` (security: `bundle exec brakeman`,
  `bundle exec bundle-audit check --update`).
- Tests: `bundle exec rspec` (RSpec; test DB is `datacite_test`). The test ES indexes
  are created automatically by the suite's `before(:suite)` hook — no manual step.
- Run the API in development: the committed `Gemfile` has **no app-server gem**
  (production uses Passenger inside Docker). To run natively, use the git-ignored
  `Gemfile.dev`, which layers Puma on top of the real Gemfile:
  `BUNDLE_GEMFILE=Gemfile.dev bundle exec rails server -b 0.0.0.0 -p 3000`
  (run `BUNDLE_GEMFILE=Gemfile.dev bundle install` once if Puma is not installed).
  Serves on `http://localhost:3000`; health check: `GET /heartbeat` → `OK`.

### Gotchas

- Listing endpoints (`/dois`, `/providers`, `/clients`) read from **OpenSearch**, not
  MySQL. After seeding/importing, index the data: `rake datacite_doi:import`,
  `rake provider:import`, `rake client:import` (or reindex a model directly, e.g.
  `DataciteDoi.__elasticsearch__.import(refresh: true)`). Only `findable` DOIs appear
  in the public `/dois` list; `draft` DOIs do not.
- Creating a Provider via the API sends a Mailgun welcome email; with placeholder
  Mailgun credentials this returns HTTP 500 even though the provider row is created.
  Creating DOIs does not send email.
- Generate an admin bearer token for authenticated API calls with
  `rake user:generate_jwt` (defaults to a `staff_admin` token).
