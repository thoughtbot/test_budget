# Test Budget

> You have a time budget for tests. This tool enforces it.

Test suites get slow one test at a time. By the time you notice, your CI takes
40 minutes and nobody wants to touch it.

Test Budget is a post-run audit tool. It reads your test results, checks
durations against your set budget, and fails if anything is over. Think of it as
**a linter for test performance**.

It doesn't change how your tests run. It just tells you when they're too slow.
Before it gets worse.

## Install

Add to your Gemfile:

```ruby
gem "test_budget"
```

> [!NOTE]
> Test Budget currently supports **RSpec only**. Minitest support is not yet available.

## Generate RSpec JSON output

> [!TIP]
> You can skip this step and run `test_budget init` without a results file to
> get started with sensible defaults right away.

Add to your RSpec configuration or CI command:

```bash
bundle exec rspec --format json --out tmp/test_timings.json
```

Or combine with your usual formatter:

```bash
bundle exec rspec --format progress --format json --out tmp/test_timings.json
```

## Quick start

Generate a starter config from an existing RSpec JSON results file:

```bash
bundle exec test_budget init tmp/test_timings.json
```

This derives suite and per-test-case budgets from your actual test data (95th
percentile + 10% buffer). If you don't have a results file yet, run without
arguments to generate a config with sensible defaults:

```bash
bundle exec test_budget init
```

Use `--force` to overwrite an existing `.test_budget.yml`.

## Configure

The `init` command creates a `.test_budget.yml` in your project root. You can
also create one manually:

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
```

- **`timings_path`** (required) — path to the RSpec JSON output file.
- **`suite.max_duration`** — total duration budget for the entire suite.
- **`per_test_case.default`** — default per-test limit. Applies to any type without a specific limit.
- **`per_test_case.<type>`** — per-test limit for a specific type. Types are inferred from file paths by singularizing the directory name (`spec/models/` -> `model`, `spec/features/` -> `feature`, `spec/system/` -> `system`, etc).
- **`allowlist`** — known slow tests to skip. Use this as a temporary escape hatch, not a permanent solution.

> [!IMPORTANT]
> At least one limit (`suite.max_duration`, `per_test_case.default`, or a type-specific limit) must be configured.

## Run

```bash
bundle exec test_budget audit
```

Use `--budget` to point to a different config file:

```bash
bundle exec test_budget audit --budget config/test_budget.yml
```

Exit code is `0` when all tests are within budget, `1` when there are violations.

## Allowlist

You can allowlist individual tests via the CLI:

```bash
bundle exec test_budget allowlist spec/models/user_spec.rb:10 --reason "Tracking in JIRA-1234"
```

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

A violation means a test is slower than you decided it should be. You have
options:

- **Make the test faster.** This is the best option. Look for unnecessary setup,
  N+1 queries, slow external calls that could be stubbed. Can the same behavior
  be exercised with a faster test type? (e.g. request -> model)
- **Split the work.** A system test doing too much can often be broken into
  focused scenarios.
- **Parallelize.** Tools like `parallel_tests` reduce wall time without changing
  individual test durations, but consider also setting per-test budgets to keep
  individual tests honest.
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
