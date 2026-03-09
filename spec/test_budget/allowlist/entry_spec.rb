# frozen_string_literal: true

RSpec.describe TestBudget::Allowlist::Entry do
  it "stores test_case_key, reason, and expires_on" do
    entry = described_class.new(test_case_key: "spec/models/user_spec.rb -- User#slow", reason: "Legacy test", expires_on: Date.today + 30)

    expect(entry.test_case_key).to eq("spec/models/user_spec.rb -- User#slow")
    expect(entry.reason).to eq("Legacy test")
    expect(entry.expires_on).to eq(Date.today + 30)
  end

  describe "#expired?" do
    it "returns true when expires_on is in the past" do
      entry = build_entry(expires_on: Date.today - 1)

      expect(entry.expired?).to be true
    end

    it "returns false when expires_on is in the future" do
      entry = build_entry(expires_on: Date.today + 1)

      expect(entry.expired?).to be false
    end

    it "returns false when expires_on is today" do
      entry = build_entry(expires_on: Date.today)

      expect(entry.expired?).to be false
    end
  end

  describe "#matches?" do
    it "returns true when key matches" do
      entry = build_entry(test_case_key: "spec/models/user_spec.rb -- User#slow")

      expect(entry.matches?("spec/models/user_spec.rb -- User#slow")).to be true
    end

    it "returns false when key does not match" do
      entry = build_entry(test_case_key: "spec/models/user_spec.rb -- User#slow")

      expect(entry.matches?("spec/models/user_spec.rb -- User#fast")).to be false
    end
  end

  describe "#obsolete?" do
    it "returns :stale when no matching test case exists" do
      entry = build_entry(test_case_key: "spec/models/deleted_spec.rb -- gone")
      budget = build_budget(per_test_case: {default: 10})
      test_run = build_test_run([build_test_case])

      expect(entry.obsolete?(test_run, budget)).to eq(:stale)
    end

    it "returns :unnecessary when matching test is within budget" do
      entry = build_entry(test_case_key: "spec/models/user_spec.rb -- example")
      budget = build_budget(per_test_case: {default: 10})
      test_run = build_test_run([build_test_case(duration: 1.0)])

      expect(entry.obsolete?(test_run, budget)).to eq(:unnecessary)
    end

    it "returns nil when matching test is over budget" do
      entry = build_entry(test_case_key: "spec/models/user_spec.rb -- example")
      budget = build_budget(per_test_case: {default: 2})
      test_run = build_test_run([build_test_case(duration: 5.0)])

      expect(entry.obsolete?(test_run, budget)).to be_nil
    end
  end

  describe "#to_h" do
    it "returns hash with test_case, reason, and expires_on" do
      expires = Date.today + 60
      entry = build_entry(test_case_key: "spec/models/user_spec.rb -- User#slow", reason: "Legacy test", expires_on: expires)

      expect(entry.to_h).to eq({
        "test_case" => "spec/models/user_spec.rb -- User#slow",
        "reason" => "Legacy test",
        "expires_on" => expires.to_s
      })
    end
  end
end
