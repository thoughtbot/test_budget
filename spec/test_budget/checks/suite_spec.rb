# frozen_string_literal: true

RSpec.describe TestBudget::Checks::Suite do
  it "returns nil when under budget" do
    budget = build_budget(suite: {max_duration: 600})
    check = described_class.new(budget)

    expect(check.check(500)).to be_nil
  end

  it "returns violation when over budget" do
    budget = build_budget(suite: {max_duration: 600})
    check = described_class.new(budget)

    result = check.check(700)

    expect(result).to be_a(TestBudget::Violation)
    expect(result.kind).to eq(:suite)
    expect(result.duration).to eq(700)
    expect(result.limit).to eq(600)
  end

  it "returns nil when max_duration is nil" do
    budget = build_budget
    check = described_class.new(budget)

    expect(check.check(9999)).to be_nil
  end

  it "returns nil for empty list" do
    budget = build_budget(suite: {max_duration: 600})
    check = described_class.new(budget)

    expect(check.check(0)).to be_nil
  end
end
