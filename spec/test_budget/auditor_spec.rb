# frozen_string_literal: true

RSpec.describe TestBudget::Auditor do
  def make_test_case(file: "spec/models/user_spec.rb", name: "example", duration: 1.0)
    TestBudget::TestCase.new(file: file, name: name, duration: duration, status: "passed", line_number: 1)
  end

  def make_test_run(test_cases)
    TestBudget::TestRun.new(test_cases: test_cases, suite_duration: test_cases.sum(&:duration))
  end

  it "returns per_test_case violations" do
    budget = build_budget(per_test_case: {default: 2})
    auditor = described_class.new(budget)

    result = auditor.audit(make_test_run([make_test_case(duration: 3.0)]))

    expect(result.violations.size).to eq(1)
    expect(result.violations.first.kind).to eq(:per_test_case)
  end

  it "returns suite violations" do
    budget = build_budget(suite: {max_duration: 5}, per_test_case: {default: 100})
    auditor = described_class.new(budget)

    result = auditor.audit(make_test_run([make_test_case(duration: 3.0), make_test_case(name: "other", duration: 3.0)]))

    expect(result.violations.map(&:kind)).to include(:suite)
  end

  it "filters allowlisted violations" do
    budget = build_budget(
      per_test_case: {default: 2},
      allowlist: ["spec/models/user_spec.rb -- example"]
    )
    auditor = described_class.new(budget)

    result = auditor.audit(make_test_run([make_test_case(duration: 3.0)]))

    expect(result.violations).to be_empty
  end

  it "returns empty when all pass" do
    budget = build_budget(per_test_case: {default: 10})
    auditor = described_class.new(budget)

    result = auditor.audit(make_test_run([make_test_case(duration: 1.0)]))

    expect(result.violations).to be_empty
  end

  describe "warnings" do
    it "returns stale warning when allowlist entry has no matching test case" do
      budget = build_budget(
        per_test_case: {default: 10},
        allowlist: ["spec/models/deleted_spec.rb -- gone"]
      )
      auditor = described_class.new(budget)

      result = auditor.audit(make_test_run([make_test_case]))

      expect(result.warnings.size).to eq(1)
      expect(result.warnings.first.kind).to eq(:stale)
    end

    it "returns unnecessary warning when allowlisted test is within budget" do
      budget = build_budget(
        per_test_case: {default: 10},
        allowlist: ["spec/models/user_spec.rb -- example"]
      )
      auditor = described_class.new(budget)

      result = auditor.audit(make_test_run([make_test_case(duration: 1.0)]))

      expect(result.warnings.size).to eq(1)
      expect(result.warnings.first.kind).to eq(:unnecessary)
    end

    it "does not warn when allowlisted test is over budget" do
      budget = build_budget(
        per_test_case: {default: 2},
        allowlist: ["spec/models/user_spec.rb -- example"]
      )
      auditor = described_class.new(budget)

      result = auditor.audit(make_test_run([make_test_case(duration: 3.0)]))

      expect(result.warnings).to be_empty
    end
  end
end
