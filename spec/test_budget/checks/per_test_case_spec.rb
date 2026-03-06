# frozen_string_literal: true

RSpec.describe TestBudget::Checks::PerTestCase do
  let(:budget) do
    build_budget(per_test_case: {default: 5, by_type: {model: 2}})
  end
  let(:check) { described_class.new(budget) }

  it "returns nil when under budget" do
    test_case = TestBudget::TestCase.new(
      file: "spec/models/user_spec.rb", name: "example",
      duration: 1.5, status: "passed", line_number: 1
    )
    expect(check.check(test_case)).to be_nil
  end

  it "returns violation when over budget" do
    test_case = TestBudget::TestCase.new(
      file: "spec/models/user_spec.rb", name: "example",
      duration: 2.5, status: "passed", line_number: 1
    )
    violation = check.check(test_case)

    expect(violation).to be_a(TestBudget::Violation)
    expect(violation.kind).to eq(:per_test_case)
    expect(violation.limit).to eq(2)
    expect(violation.duration).to eq(2.5)
  end

  it "returns nil when exactly at budget" do
    test_case = TestBudget::TestCase.new(
      file: "spec/models/user_spec.rb", name: "example",
      duration: 2.0, status: "passed", line_number: 1
    )
    expect(check.check(test_case)).to be_nil
  end

  it "uses type-specific limit when available" do
    test_case = TestBudget::TestCase.new(
      file: "spec/models/user_spec.rb", name: "example",
      duration: 3.0, status: "passed", line_number: 1
    )
    violation = check.check(test_case)
    expect(violation.limit).to eq(2)
  end

  it "falls back to default limit for unknown types" do
    test_case = TestBudget::TestCase.new(
      file: "spec/lib/utils_spec.rb", name: "example",
      duration: 6.0, status: "passed", line_number: 1
    )
    violation = check.check(test_case)
    expect(violation.limit).to eq(5)
  end
end
