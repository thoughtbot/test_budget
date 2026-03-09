# frozen_string_literal: true

RSpec.describe TestBudget::Reporter do
  let(:reporter) { described_class.new(budget_path: ".test_budget.yml") }

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

  def make_warning(test_case_key: "spec/models/old_spec.rb -- old test", reason: "legacy", kind: :stale)
    entry = TestBudget::Allowlist::Entry.new(test_case_key: test_case_key, reason: reason)
    TestBudget::Warning.new(entry: entry, kind: kind)
  end

  it "prints all clear when no violations" do
    expect { reporter.report(make_result) }.to output(/all clear/).to_stdout
  end

  it "prints numbered violations" do
    violations = [
      make_per_test_violation,
      make_per_test_violation(file: "spec/models/post_spec.rb", name: "Post#title", duration: 3.0, limit: 2.0)
    ]

    expect { reporter.report(make_result(violations: violations)) }
      .to output(/1\).*User#slow.*2\).*Post#title/m).to_stdout
  end

  it "includes allowlist command for per_test_case violations" do
    expect { reporter.report(make_result(violations: [make_per_test_violation])) }
      .to output(/bundle exec test_budget allowlist spec\/models\/user_spec\.rb:1/).to_stdout
  end

  it "handles mixed violation types" do
    violations = [make_per_test_violation, make_suite_violation]

    expect { reporter.report(make_result(violations: violations)) }
      .to output(/User#slow.*Suite total/m).to_stdout
  end

  it "uses custom budget path in allowlist command" do
    custom_reporter = described_class.new(budget_path: "config/my_budget.yml")

    expect { custom_reporter.report(make_result(violations: [make_per_test_violation])) }
      .to output(/--budget config\/my_budget\.yml/).to_stdout
  end

  it "prints warnings to stderr" do
    warnings = [make_warning]

    expect { reporter.report(make_result(warnings: warnings)) }
      .to output(/Warning: obsolete allowlist entry \(stale\)/).to_stderr
  end

  it "does not mix warnings into stdout" do
    warnings = [make_warning(kind: :unnecessary)]

    expect { reporter.report(make_result(warnings: warnings)) }
      .to output(satisfy { |out| out.include?("all clear") && !out.include?("Warning") }).to_stdout
  end
end
