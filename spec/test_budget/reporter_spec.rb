# frozen_string_literal: true

RSpec.describe TestBudget::Reporter do
  let(:output) { StringIO.new }
  let(:reporter) { described_class.new(output: output) }

  def make_per_test_violation(file: "spec/models/user_spec.rb", name: "User#slow", duration: 2.5, limit: 2.0)
    test_case = TestBudget::TestCase.new(file: file, name: name, duration: duration, status: "passed", line_number: 1)
    TestBudget::Violation.new(test_case: test_case, duration: duration, limit: limit, kind: :per_test_case)
  end

  def make_suite_violation(duration: 650.0, limit: 600.0)
    TestBudget::Violation.new(test_case: nil, duration: duration, limit: limit, kind: :suite)
  end

  it "prints all clear when no violations" do
    reporter.report([])
    expect(output.string).to include("all clear")
  end

  it "prints numbered violations" do
    violations = [
      make_per_test_violation,
      make_per_test_violation(file: "spec/models/post_spec.rb", name: "Post#title", duration: 3.0, limit: 2.0)
    ]
    reporter.report(violations)

    expect(output.string).to include("1)")
    expect(output.string).to include("2)")
    expect(output.string).to include("User#slow")
    expect(output.string).to include("Post#title")
  end

  it "includes allowlist snippets for per_test_case violations" do
    reporter.report([make_per_test_violation])
    expect(output.string).to include("- test_case: \"spec/models/user_spec.rb -- User#slow\"")
  end

  it "handles mixed violation types" do
    violations = [make_per_test_violation, make_suite_violation]
    reporter.report(violations)

    expect(output.string).to include("User#slow")
    expect(output.string).to include("Suite total")
  end
end
