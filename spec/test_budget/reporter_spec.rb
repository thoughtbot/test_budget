# frozen_string_literal: true

RSpec.describe TestBudget::Reporter do
  let(:reporter) { described_class.new(budget_path: ".test_budget.yml") }

  it "prints all clear when no violations" do
    expect { reporter.report(build_result) }.to output(/all clear/).to_stdout
  end

  it "prints numbered violations" do
    violations = [
      build_per_test_violation,
      build_per_test_violation(file: "spec/models/post_spec.rb", name: "Post#title", duration: 3.0, limit: 2.0)
    ]

    expect { reporter.report(build_result(violations: violations)) }
      .to output(/1\).*User#slow.*2\).*Post#title/m).to_stdout
  end

  it "includes allowlist command for per_test_case violations" do
    expect { reporter.report(build_result(violations: [build_per_test_violation])) }
      .to output(/bundle exec test_budget allowlist spec\/models\/user_spec\.rb:1/).to_stdout
  end

  it "handles mixed violation types" do
    violations = [build_per_test_violation, build_suite_violation]

    expect { reporter.report(build_result(violations: violations)) }
      .to output(/User#slow.*Suite total/m).to_stdout
  end

  it "uses custom budget path in allowlist command" do
    custom_reporter = described_class.new(budget_path: "config/my_budget.yml")

    expect { custom_reporter.report(build_result(violations: [build_per_test_violation])) }
      .to output(/--budget config\/my_budget\.yml/).to_stdout
  end

  it "prints warnings to stderr" do
    expect { reporter.report(build_result(warnings: [build_warning])) }
      .to output(/Warning: obsolete allowlist entry \(stale\)/).to_stderr
  end

  it "does not mix warnings into stdout" do
    expect { reporter.report(build_result(warnings: [build_warning(kind: :unnecessary)])) }
      .to output(satisfy { |out| out.include?("all clear") && !out.include?("Warning") }).to_stdout
  end
end
