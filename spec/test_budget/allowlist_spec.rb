# frozen_string_literal: true

RSpec.describe TestBudget::Allowlist do
  describe "#allowed?" do
    it "returns true when key matches an entry" do
      allowlist = described_class.new([
        {"test_case" => "spec/models/user_spec.rb -- User#slow", "reason" => "Legacy"}
      ])

      expect(allowlist.allowed?("spec/models/user_spec.rb -- User#slow")).to be true
    end

    it "returns false when no entry matches" do
      allowlist = described_class.new

      expect(allowlist.allowed?("spec/models/user_spec.rb -- User#slow")).to be false
    end
  end

  describe "#add" do
    it "adds an entry and returns it" do
      allowlist = described_class.new

      entry = allowlist.add("spec/models/user_spec.rb -- User#slow", reason: "Legacy")

      expect(entry).to be_a(TestBudget::Allowlist::Entry)
      expect(entry.test_case_key).to eq("spec/models/user_spec.rb -- User#slow")
      expect(entry.reason).to eq("Legacy")
      expect(allowlist.allowed?("spec/models/user_spec.rb -- User#slow")).to be true
    end

    it "raises Error on duplicate" do
      allowlist = described_class.new([
        {"test_case" => "spec/models/user_spec.rb -- User#slow", "reason" => "Legacy"}
      ])

      expect {
        allowlist.add("spec/models/user_spec.rb -- User#slow", reason: "Again")
      }.to raise_error(TestBudget::Error, /already allowlisted/i)
    end
  end

  describe "#to_a" do
    it "returns a copy of entries" do
      allowlist = described_class.new([
        {"test_case" => "spec/models/user_spec.rb -- User#slow", "reason" => "Legacy"}
      ])
      result = allowlist.to_a

      expect(result.size).to eq(1)
      expect(result.first).to be_a(TestBudget::Allowlist::Entry)
    end
  end
end
