# benchmark.fyi

Share [benchmark-ips](https://github.com/evanphx/benchmark-ips) results as a URL instead of a screenshot.

Hosted instance: **https://ips.fastruby.io**

## Why

`benchmark-ips` measures how many iterations per second your Ruby code manages, and prints a table to your terminal:

```
Warming up --------------------------------------
      string concat    1.234M i/100ms
Calculating -------------------------------------
      string concat   12.345M (± 1.2%) i/s -     61.725M in   5.001234s
```

That output is awkward to share. Pasting it into an issue loses the formatting, and a screenshot can't be compared against anything.

This app takes the same data and gives you a short link that renders it as a table, bolds the fastest entry, flags entries whose standard deviation is high enough to distrust, and optionally shows how many times slower each entry is than the winner. Useful in a bug report, a PR description, or a blog post about a performance fix.

## Sharing a benchmark

Install the gem:

```ruby
# Gemfile
gem 'benchmark-ips'
```

Write a benchmark. Each `x.report` block is one entry in the shared table, and
`x.compare!` adds the times-slower column:

```ruby
require 'benchmark/ips'

Benchmark.ips do |x|
  # Optional. Defaults are 2s warmup and 5s per report.
  x.config(warmup: 1, time: 2)

  a, b, c = "a", "b", "c"

  x.report("interpolation") { "#{a}#{b}#{c}" }
  x.report("concat (+)")    { a + b + c }
  x.report("<< buffer")     { (+"") << a << b << c }
  x.report("format")        { format("%s%s%s", a, b, c) }

  # Adds the "times slower" column to the shared report.
  x.compare!
end
```

Two ready-to-run files live in `examples/`:

| File | What it is for |
|---|---|
| `examples/smoke_benchmark.rb` | The benchmark above. Checks that an instance accepts and renders a report. |
| `examples/legacy_client_benchmark.rb` | Same, pinned to benchmark-ips 2.14.0, to exercise the pre-2.15.0 request shape. |

```bash
ruby examples/smoke_benchmark.rb
```

Run it with `SHARE=1`:

```bash
SHARE=1 ruby my_benchmark.rb
```

The gem POSTs the results and prints the URL:

```
Shared at: https://ips.fastruby.io/2Bq
```

Report ids are base58-encoded row ids, so early ones on a fresh instance are a
single character (`/2`, `/3`). That is a real link, not a truncated one.

To send results to your own instance instead, set `SHARE_URL` (which enables sharing on its own, no `SHARE` needed):

```bash
SHARE_URL=http://localhost:3000 ruby my_benchmark.rb
```

## Running it locally

Requirements:

- Ruby **4.0.6** (see `.tool-versions`)
- PostgreSQL

`config/database.yml` is intentionally not in the repo. Create it before anything else, or setup will fail:

```bash
cp config/database.yml.github config/database.yml
```

That template uses the `postgres` role over TCP, which suits CI. If you run PostgreSQL locally via Homebrew, a minimal version that uses your own account and the local socket works better:

```yaml
default: &default
  adapter: postgresql
  encoding: unicode
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>

development:
  <<: *default
  database: benchmark_fyi_development

test:
  <<: *default
  database: benchmark_fyi_test
```

Then install dependencies and create the databases:

```bash
./bin/setup
```

Start the server:

```bash
bin/dev
```

That is a thin wrapper around `bin/rails server` that tells you what to do if
`config/database.yml` is missing. Arguments pass through, so `bin/dev -p 4000`
works. There is no asset watcher to run alongside it, so it is not the
foreman-and-`Procfile.dev` version Rails generates for apps that have one.

Visit http://localhost:3000 and share a benchmark at it using the `SHARE_URL` example above.

## Verifying a change end to end

The suite uses Rack::Test, so it never exercises the real server or a real
client. To check a change for real, start the app and point an actual benchmark
at it:

```bash
bin/dev
SHARE_URL=http://localhost:3000 ruby examples/smoke_benchmark.rb
```

Then confirm what was stored:

```bash
bin/rails runner 'r = Report.last; puts r.short_id; puts r.entries.map { |e| e["name"] }.inspect'
```

The same works against a deployed instance, which is how a review app gets
checked:

```bash
SHARE_URL=https://your-app.herokuapp.com ruby my_benchmark.rb
heroku logs --tail -a your-app
heroku run --no-tty -a your-app -- bin/rails runner 'puts Report.count'
```

## Tests

```bash
bin/rails test
```

The app dual-boots so the next Rails version can be tested before committing to it. `Gemfile` tracks Rails 7.1 and `Gemfile.next` tracks 7.2; CI runs both. To run the suite against the next version:

```bash
BUNDLE_GEMFILE=Gemfile.next bundle install
BUNDLE_GEMFILE=Gemfile.next bin/rails test
```

## The API

`POST /reports` with a JSON body. Each entry needs `name`, `ips`, `stddev`, `microseconds`, `iterations` and `cycles`; anything missing gets a 400. `central_tendency` and `error` are accepted and optional, as are the top-level `ruby`, `os` and `arch` fields.

```json
{
  "entries": [
    {
      "name": "concat",
      "ips": 12345678.9,
      "stddev": 123456.7,
      "microseconds": 5001234.0,
      "iterations": 61725000,
      "cycles": 1234000
    }
  ],
  "options": { "compare": true }
}
```

The response is the report's short id, which is also its path:

```json
{ "id": "2Bq" }
```

`GET /:id` renders that report.

`benchmark-ips` before 2.15.0 sent this body with no content type, and
`Net::HTTP` then supplied `application/x-www-form-urlencoded`, so Rails parsed
the JSON as form data. `ReportsController#fix_missing_json_content_type` repairs
that by re-reading the raw body, which only works while rack rewinds
`rack.input` after form parsing. Rack 2.x does, rack 3 does not. That is why
`rack` is pinned to `~> 2.2`, and `test/integration/create_report_test.rb`
covers both request shapes.

If you touch that code path, test it against a real old client with
`examples/legacy_client_benchmark.rb`. Installing the old gem is not enough on
its own, because `require` activates the newest installed version, so that file
pins it at require time with `gem 'benchmark-ips', '2.14.0'`.

A legacy request logs `Parameters: {"{\"entries\":" => ...}` before the repair
runs; a modern one logs properly parsed JSON. That log line is how you tell
which path you actually exercised.

## Contributing

Issues and pull requests welcome at https://github.com/fastruby/benchmark.fyi. Please make sure `bin/rails test` passes against both `Gemfile` and `Gemfile.next`.

Originally built by Evan Phoenix ([evanphx](https://github.com/evanphx)), who also wrote `benchmark-ips`. [FastRuby.io](https://www.fastruby.io) maintains this app and the hosted instance.
