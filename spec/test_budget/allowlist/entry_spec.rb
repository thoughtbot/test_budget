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

  describe "#to_h" do
    it "returns hash with test_case and reason" do
      entry = described_class.new(test_case_key: "spec/models/user_spec.rb -- User#slow", reason: "Legacy test")

      expect(entry.to_h).to eq({"test_case" => "spec/models/user_spec.rb -- User#slow", "reason" => "Legacy test"})
    end
  end
end
