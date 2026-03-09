# frozen_string_literal: true

RSpec.describe TestBudget::Allowlist::Entry do
  it "stores test_case_key and reason" do
    entry = described_class.new(test_case_key: "spec/models/user_spec.rb -- User#slow", reason: "Legacy test")

    expect(entry.test_case_key).to eq("spec/models/user_spec.rb -- User#slow")
    expect(entry.reason).to eq("Legacy test")
  end

  describe "#matches?" do
    it "returns true when key matches" do
      entry = described_class.new(test_case_key: "spec/models/user_spec.rb -- User#slow", reason: "Legacy test")

      expect(entry.matches?("spec/models/user_spec.rb -- User#slow")).to be true
    end

    it "returns false when key does not match" do
      entry = described_class.new(test_case_key: "spec/models/user_spec.rb -- User#slow", reason: "Legacy test")

      expect(entry.matches?("spec/models/user_spec.rb -- User#fast")).to be false
    end
  end

  describe "#obsolete?" do
    it "returns :stale when no matching test case exists" do
      entry = described_class.new(test_case_key: "spec/models/deleted_spec.rb -- gone", reason: "old")
      budget = build_budget(per_test_case: {default: 10})
      test_run = build_test_run([build_test_case])

      expect(entry.obsolete?(test_run, budget)).to eq(:stale)
    end

    it "returns :unnecessary when matching test is within budget" do
      entry = described_class.new(test_case_key: "spec/models/user_spec.rb -- example", reason: "old")
      budget = build_budget(per_test_case: {default: 10})
      test_run = build_test_run([build_test_case(duration: 1.0)])

      expect(entry.obsolete?(test_run, budget)).to eq(:unnecessary)
    end

    it "returns nil when matching test is over budget" do
      entry = described_class.new(test_case_key: "spec/models/user_spec.rb -- example", reason: "old")
      budget = build_budget(per_test_case: {default: 2})
      test_run = build_test_run([build_test_case(duration: 5.0)])

      expect(entry.obsolete?(test_run, budget)).to be_nil
    end
  end

  describe "#to_h" do
    it "returns hash with test_case and reason" do
      entry = described_class.new(test_case_key: "spec/models/user_spec.rb -- User#slow", reason: "Legacy test")

      expect(entry.to_h).to eq({"test_case" => "spec/models/user_spec.rb -- User#slow", "reason" => "Legacy test"})
    end
  end
end
