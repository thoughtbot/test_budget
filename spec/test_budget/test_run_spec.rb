# frozen_string_literal: true

RSpec.describe TestBudget::TestRun do
  describe "#over?" do
    it "returns nil when under budget" do
      budget = build_budget(suite: {max_duration: 600})
      test_run = described_class.new(test_cases: [], suite_duration: 500)

      expect(test_run.over?(budget)).to be_nil
    end

    it "returns violation when over budget" do
      budget = build_budget(suite: {max_duration: 600})
      test_run = described_class.new(test_cases: [], suite_duration: 700)

      result = test_run.over?(budget)

      expect(result).to be_a(TestBudget::Violation)
      expect(result.kind).to eq(:suite)
      expect(result.duration).to eq(700)
      expect(result.limit).to eq(600)
    end

    it "returns nil when max_duration is nil" do
      budget = build_budget
      test_run = described_class.new(test_cases: [], suite_duration: 9999)

      expect(test_run.over?(budget)).to be_nil
    end

    it "returns nil when duration is zero" do
      budget = build_budget(suite: {max_duration: 600})
      test_run = described_class.new(test_cases: [], suite_duration: 0)

      expect(test_run.over?(budget)).to be_nil
    end
  end
end
