## [Unreleased]

- Add `breakdown` command to show time distribution across test types

```
$ bundle exec test_budget breakdown
Test Type         Count  % Count   Duration   % Time
---------------------------------------------------
system                4    8.0%     4m 16s    66.2%
request              12   24.0%     1m 18s    20.2%
model                30   60.0%        50s    12.9%
job                   4    8.0%         3s     0.8%
---------------------------------------------------
Total                50              6m 27s
```

## [0.1.0] - 2026-03-09

- Initial release
