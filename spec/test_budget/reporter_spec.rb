# frozen_string_literal: true

RSpec.describe TestBudget::Reporter do
  let(:output) { StringIO.new }
  let(:reporter) { described_class.new(output: output, budget_path: ".test_budget.yml") }

  def make_result(violations: [], warnings: [])
    TestBudget::Audit::Result.new(violations: violations, warnings: warnings)
  end

  def make_per_test_violation(file: "spec/models/user_spec.rb", name: "User#slow", duration: 2.5, limit: 2.0)
    test_case = TestBudget::TestCase.new(file: file, name: name, duration: duration, status: "passed", line_number: 1)
    TestBudget::Violation.new(test_case: test_case, duration: duration, limit: limit, kind: :per_test_case)
  end

  def make_suite_violation(duration: 650.0, limit: 600.0)
    TestBudget::Violation.new(test_case: nil, duration: duration, limit: limit, kind: :suite)
  end

  def capture_stderr
    original = $stderr
    $stderr = StringIO.new
    yield
    $stderr.string
  ensure
    $stderr = original
  end

  def make_warning(test_case_key: "spec/models/old_spec.rb -- old test", reason: "legacy", kind: :stale)
    entry = TestBudget::Allowlist::Entry.new(test_case_key: test_case_key, reason: reason)
    TestBudget::Warning.new(entry: entry, kind: kind)
  end

  it "prints all clear when no violations" do
    reporter.report(make_result)
    expect(output.string).to include("all clear")
  end

  it "prints numbered violations" do
    violations = [
      make_per_test_violation,
      make_per_test_violation(file: "spec/models/post_spec.rb", name: "Post#title", duration: 3.0, limit: 2.0)
    ]
    reporter.report(make_result(violations: violations))

    expect(output.string).to include("1)")
    expect(output.string).to include("2)")
    expect(output.string).to include("User#slow")
    expect(output.string).to include("Post#title")
  end

  it "includes allowlist command for per_test_case violations" do
    reporter.report(make_result(violations: [make_per_test_violation]))
    expect(output.string).to include("bundle exec test_budget allowlist spec/models/user_spec.rb:1")
  end

  it "handles mixed violation types" do
    violations = [make_per_test_violation, make_suite_violation]
    reporter.report(make_result(violations: violations))

    expect(output.string).to include("User#slow")
    expect(output.string).to include("Suite total")
  end

  it "uses custom budget path in allowlist command" do
    custom_reporter = described_class.new(output: output, budget_path: "config/my_budget.yml")
    custom_reporter.report(make_result(violations: [make_per_test_violation]))

    expect(output.string).to include("--budget config/my_budget.yml")
    expect(output.string).not_to include(".test_budget.yml")
  end

  it "prints warnings to stderr" do
    warnings = [make_warning]
    stderr = capture_stderr { reporter.report(make_result(warnings: warnings)) }

    expect(stderr).to include("Warning: obsolete allowlist entry (stale)")
  end

  it "does not mix warnings into stdout" do
    warnings = [make_warning(kind: :unnecessary)]
    capture_stderr { reporter.report(make_result(warnings: warnings)) }

    expect(output.string).to include("all clear")
    expect(output.string).not_to include("Warning")
  end
end
