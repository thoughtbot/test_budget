# frozen_string_literal: true

RSpec.describe TestBudget::Auditor do
  def make_test_case(file: "spec/models/user_spec.rb", name: "example", duration: 1.0)
    TestBudget::TestCase.new(file: file, name: name, duration: duration, status: "passed")
  end

  it "returns per_test_case violations" do
    budget = build_budget(per_test_case: {default: 2})
    auditor = described_class.new(budget)

    violations = auditor.audit([make_test_case(duration: 3.0)])

    expect(violations.size).to eq(1)
    expect(violations.first.kind).to eq(:per_test_case)
  end

  it "returns suite violations" do
    budget = build_budget(suite: {max_duration: 5}, per_test_case: {default: 100})
    auditor = described_class.new(budget)

    violations = auditor.audit([make_test_case(duration: 3.0), make_test_case(name: "other", duration: 3.0)])

    expect(violations.map(&:kind)).to include(:suite)
  end

  it "filters allowlisted violations" do
    budget = build_budget(
      per_test_case: {default: 2},
      allowlist: ["spec/models/user_spec.rb -- example"]
    )
    auditor = described_class.new(budget)

    violations = auditor.audit([make_test_case(duration: 3.0)])

    expect(violations).to be_empty
  end

  it "returns empty when all pass" do
    budget = build_budget(per_test_case: {default: 10})
    auditor = described_class.new(budget)

    violations = auditor.audit([make_test_case(duration: 1.0)])

    expect(violations).to be_empty
  end
end
