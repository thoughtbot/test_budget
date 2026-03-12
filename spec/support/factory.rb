# frozen_string_literal: true

module Factory
  def build_budget(per_test_case: nil, suite: nil, allowlist: [])
    TestBudget::Budget.new(
      path: nil,
      timings_path: nil,
      suite: TestBudget::Budget::Suite.new(max_duration: suite&.dig(:max_duration)),
      per_test_case: TestBudget::Budget::PerTestCase.new(
        default: per_test_case&.dig(:default),
        types: per_test_case&.dig(:types) || {}
      ),
      allowlist: TestBudget::Allowlist.new(
        allowlist.map { |key| {"test_case" => key, "reason" => "test", "expires_on" => (Date.today + 365).to_s} }
      )
    )
  end

  def build_test_case(file: "spec/models/user_spec.rb", name: "example", duration: 1.0)
    TestBudget::TestCase.new(file: file, name: name, duration: duration, status: "passed", line_number: 1)
  end

  def build_test_run(test_cases)
    TestBudget::TestRun.new(test_cases: test_cases, wall_time: test_cases.sum(&:duration))
  end

  def build_result(violations: [], warnings: [])
    TestBudget::Audit::Result.new(violations: violations, warnings: warnings)
  end

  def build_per_test_violation(file: "spec/models/user_spec.rb", name: "User#slow", duration: 2.5, limit: 2.0)
    test_case = build_test_case(file: file, name: name, duration: duration)
    TestBudget::Violation.new(test_case: test_case, duration: duration, limit: limit, kind: :per_test_case)
  end

  def build_suite_violation(duration: 650.0, limit: 600.0)
    TestBudget::Violation.new(test_case: nil, duration: duration, limit: limit, kind: :suite)
  end

  def build_warning(test_case_key: "spec/models/old_spec.rb -- old test", reason: "legacy", kind: :stale)
    entry = build_entry(test_case_key: test_case_key, reason: reason)
    TestBudget::Warning.new(entry: entry, kind: kind)
  end

  def build_entry(test_case_key: "spec/models/user_spec.rb -- User is valid", reason: "legacy test", expires_on: Date.today + 365)
    TestBudget::Allowlist::Entry.new(test_case_key: test_case_key, reason: reason, expires_on: expires_on)
  end
end
