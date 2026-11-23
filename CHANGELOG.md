## [Unreleased]

## [0.2.0] - 2026-11-23

- Add `diff` command to compare two test runs

```
$ bundle exec test_budget diff tmp/before.json tmp/after.json
┌───────────┬─────────┬─────────┬────────────┬─────────┐
│ Test Type │ Δ Count │       % │ Δ Duration │       % │
├───────────┼─────────┼─────────┼────────────┼─────────┤
│ system    │      -2 │  -50.0% │     -3m 8s │  -73.4% │
│ request   │      +5 │  +41.7% │       +32s │  +41.0% │
│ job       │      +4 │     new │        +3s │     new │
├───────────┼─────────┼─────────┼────────────┼─────────┤
│ Total     │      +7 │  +14.0% │    -2m 33s │  -39.5% │
└───────────┴─────────┴─────────┴────────────┴─────────┘
```

- Add `breakdown` command to show time distribution across test types

```
$ bundle exec test_budget breakdown
┌───────────┬───────┬───────┬──────────┬───────┐
│ Test Type │ Count │     % │ Duration │     % │
├───────────┼───────┼───────┼──────────┼───────┤
│ system    │     4 │  8.0% │   4m 16s │ 66.2% │
│ request   │    12 │ 24.0% │   1m 18s │ 20.2% │
│ model     │    30 │ 60.0% │      50s │ 12.9% │
│ job       │     4 │  8.0% │       3s │  0.8% │
├───────────┼───────┼───────┼──────────┼───────┤
│ Total     │    50 │       │   6m 27s │       │
└───────────┴───────┴───────┴──────────┴───────┘
```

- Add `--sort` flag to `breakdown` command (`duration`, `count`, or `type`)

## [0.1.0] - 2026-03-09

- Initial release
