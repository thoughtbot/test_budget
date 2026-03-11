# Test Budget

> Prevent slow tests from creeping into your suite.

Test suites get slow one test at a time. By the time you notice, your CI takes
40 minutes and nobody wants to touch it.

Test Budget is **a linter for test performance**. It reads your test results
after the run, checks durations against configured budgets, and fails if
anything goes over.

It doesn't change how your tests run. It just tells you when they're too slow —
before it gets worse.

## Install

Add to your Gemfile:

```ruby
gem "test_budget"
```

> [!NOTE]
> Test Budget currently supports **RSpec only**. Minitest support is not yet available.

## Quick start

Three steps: generate timing data, create a budget config, then audit.

**1. Run your tests with JSON output** to collect timing data:

```bash
bundle exec rspec --format progress --format json --out tmp/test_timings.json
```

> [!NOTE]
> Using a parallel runner? See [this section](#parallel-test-runners)
> for setup instructions.

**2. Generate a budget config** from the timing data:

```bash
bundle exec test_budget init tmp/test_timings.json
```

This creates `.test_budget.yml` with budgets derived from your actual data
(see [Configuration](#configuration) for details). Edit it freely to match your
standards.

> [!TIP]
> Don't want to generate timing data first? Run `bundle exec test_budget init`
> without arguments to create a config with Rails defaults instead.

**3. Audit your test suite** against the budget:

```bash
bundle exec rspec --format progress --format json --out tmp/test_timings.json
bundle exec test_budget audit
```

Example output:

```
Test budget: 1 violation(s) found

  1) spec/system/signup_spec.rb -- creates account (11.20s) exceeds system limit (6.00s)
     To allowlist, run:
     bundle exec test_budget allowlist spec/system/signup_spec.rb:15 --reason "<reason>"
```

That's it. From here on, run the audit after every test run (see [CI
integration](#ci-integration)).

### Init options

Use `--force` to overwrite an existing `.test_budget.yml`.

`estimate` is an alias for `init`. Use whichever name feels right:

```bash
bundle exec test_budget estimate tmp/test_timings.json
```

### Parallel test runners

If you use [`parallel_tests`][parallel_tests],
`$TEST_ENV_NUMBER` in command arguments is replaced per worker (empty string for
worker 1, `2` for worker 2, etc.). Use it to write a separate output file per
worker:

```bash
bundle exec parallel_rspec -- --format json --out 'tmp/test_timings$TEST_ENV_NUMBER.json'
```

This produces `test_timings.json`, `test_timings2.json`, `test_timings3.json`,
etc. Then set your `timings_path` to a glob pattern:

```yaml
timings_path: "tmp/test_timings*.json"
```

If you use [`flatware`][flatware], each worker appends its results to the same
output file. Test Budget handles this automatically:

```bash
flatware rspec --format json --out tmp/test_timings.json
```

## Configuration

The `init` command creates a `.test_budget.yml` in your project root with
budgets based on your actual data (per-test limits use the 99th percentile
rounded to the nearest 0.5s; the suite limit uses total duration + 10%
headroom). The generated file is a starting point — edit it freely to
match your team's standards. You can also create one manually:

```yaml
timings_path: tmp/test_timings.json

suite:
  max_duration: 300 # seconds

per_test_case:
  default: 2
  system: 6
  request: 3
  model: 1.5

allowlist:
  - test_case: "spec/services/invoice_pdf_spec.rb -- generates PDF with line items"
    reason: "PDF generation is inherently slow, tracking in JIRA-1234"
    expires_on: "2025-06-01"
```

- **`timings_path`** (required) — path (or glob pattern) to the RSpec JSON output file(s).
- **`suite.max_duration`** — total duration budget for the entire suite.
- **`per_test_case.default`** — default per-test limit. Applies to any type without a specific limit.
- **`per_test_case.<type>`** — per-test limit for a specific type. Types are inferred from file paths by singularizing the directory name (`spec/models/` -> `model`, `spec/features/` -> `feature`, `spec/system/` -> `system`, etc).
- **`allowlist`** — known slow tests to skip. Each entry requires an `expires_on` date (YYYY-MM-DD). Expired entries stop exempting their tests. Use this as a temporary escape hatch, not a permanent solution.

> [!IMPORTANT]
> At least one limit (`suite.max_duration`, `per_test_case.default`, or a type-specific limit) must be configured.

## Audit

```bash
bundle exec test_budget audit
```

Use `--budget` to point to a different config file:

```bash
bundle exec test_budget audit --budget config/test_budget.yml
```

Use `--tolerant` to apply a 10% tolerance to all limits. This is useful on
shared CI infrastructure where CPU contention causes small fluctuations in test
durations:

```bash
bundle exec test_budget audit --tolerant
```

With `--tolerant`, a test only fails if it exceeds the limit by more than 10%
(e.g., a 5s limit becomes an effective 5.5s limit).

Exit code is `0` when all tests are within budget, `1` when there are violations.

## Allowlist

You can allowlist individual tests via the CLI:

```bash
bundle exec test_budget allowlist spec/models/user_spec.rb:10 --reason "Tracking in JIRA-1234"
```

Entries are created with a 60-day expiration by default. Edit the `expires_on`
date in the YAML file if you need a different window.

### Pruning obsolete entries

Over time, allowlisted tests may be fixed or removed. Use `prune` to clean up
entries that are no longer needed:

```bash
bundle exec test_budget prune
```

This removes **stale** entries (test no longer exists) and **unnecessary** entries
(test is now within budget). The `audit` command also warns about these entries
so you know when it's time to prune.

### Example output

```
Test budget: 2 violation(s) found

  1) spec/models/user_spec.rb -- User#full_name (2.50s) exceeds model limit (1.00s)
     To allowlist, run:
     bundle exec test_budget allowlist spec/models/user_spec.rb:10 --reason "<reason>"

  2) Suite total (650.00s) exceeds limit (600.00s)
```

## CI integration

Run the audit after your test suite:

```yaml
# .github/workflows/ci.yml
- run: bundle exec rspec --format progress --format json --out tmp/test_timings.json
- run: bundle exec test_budget audit
```

The second step fails the build if any test exceeds its budget.

## I have violations. Now what?

Violations mean tests are slower than you decided they should be. You have
options:

- **Make the tests faster.** This is the best option. Look for unnecessary
  setup, N+1 queries, slow external calls that could be stubbed. Can the same
  behavior be exercised with a faster test type? (e.g. system -> request,
  request -> model)
- **Split the work.** A test doing too much can often be broken into
  focused scenarios.
- **Parallelize.** Tools like [`parallel_tests`][parallel_tests] and
  [`flatware`][flatware] reduce wall time without changing individual test
  durations, but consider also setting per-test budgets to keep individual tests
  honest.
- **Upgrade infrastructure.** Faster CI (or developer) machines buy time.
- **Allowlist temporarily.** If a fix isn't immediate, add the test to the
  allowlist and create a ticket. This keeps the budget enforced for everything
  else.

The goal isn't zero violations on day one. It's to stop the bleeding and make
test performance visible.

## License

The gem is available as open source under the terms of the [MIT
License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Test Budget project's codebases, issue trackers,
chat rooms and mailing lists is expected to follow the [code of
conduct](https://github.com/thoughtbot/test_budget/blob/main/CODE_OF_CONDUCT.md).

<!-- START /templates/footer.md -->

## About thoughtbot

![thoughtbot](https://thoughtbot.com/thoughtbot-logo-for-readmes.svg)

This repo is maintained and funded by thoughtbot, inc. The names and logos for
thoughtbot are trademarks of thoughtbot, inc.

We love open source software! See [our other projects][community]. We are
[available for hire][hire].

[community]: https://thoughtbot.com/community?utm_source=github&utm_medium=readme&utm_campaign=test_budget
[hire]: https://thoughtbot.com/hire-us?utm_source=github&utm_medium=readme&utm_campaign=test_budget

<!-- END /templates/footer.md -->

[parallel_tests]: https://github.com/grosser/parallel_tests
[flatware]: https://github.com/briandunn/flatware
