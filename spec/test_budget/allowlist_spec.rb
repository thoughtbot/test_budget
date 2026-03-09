# frozen_string_literal: true

RSpec.describe TestBudget::Allowlist do
  let(:future_date) { (Date.today + 365).to_s }

  describe "#allowed?" do
    it "returns matching entry" do
      allowlist = described_class.new([
        {"test_case" => "spec/models/user_spec.rb -- User#slow", "reason" => "Legacy", "expires_on" => future_date}
      ])

      entry = allowlist.allowed?("spec/models/user_spec.rb -- User#slow")

      expect(entry).to be_a(TestBudget::Allowlist::Entry)
      expect(entry.test_case_key).to eq("spec/models/user_spec.rb -- User#slow")
    end

    it "returns nil when no entry matches" do
      allowlist = described_class.new

      expect(allowlist.allowed?("spec/models/user_spec.rb -- User#slow")).to be_nil
    end
  end

  describe "#add" do
    it "adds an entry and returns it" do
      allowlist = described_class.new
      expires = Date.today + 60

      entry = allowlist.add("spec/models/user_spec.rb -- User#slow", reason: "Legacy", expires_on: expires)

      expect(entry).to be_a(TestBudget::Allowlist::Entry)
      expect(entry.test_case_key).to eq("spec/models/user_spec.rb -- User#slow")
      expect(entry.reason).to eq("Legacy")
      expect(entry.expires_on).to eq(expires)
      expect(allowlist.allowed?("spec/models/user_spec.rb -- User#slow")).to be_truthy
    end

    it "raises Error on duplicate" do
      allowlist = described_class.new([
        {"test_case" => "spec/models/user_spec.rb -- User#slow", "reason" => "Legacy", "expires_on" => future_date}
      ])

      expect {
        allowlist.add("spec/models/user_spec.rb -- User#slow", reason: "Again", expires_on: Date.today + 60)
      }.to raise_error(TestBudget::Error, /already allowlisted/i)
    end
  end

  describe "validation" do
    it "raises Error when expires_on is missing" do
      expect {
        described_class.new([{"test_case" => "spec/foo.rb -- bar", "reason" => "test"}])
      }.to raise_error(TestBudget::Error, /expires_on/)
    end

    it "raises Error when expires_on is invalid" do
      expect {
        described_class.new([{"test_case" => "spec/foo.rb -- bar", "reason" => "test", "expires_on" => "not-a-date"}])
      }.to raise_error(TestBudget::Error, /expires_on/)
    end
  end

  describe "#prune" do
    it "removes stale entries and returns them" do
      allowlist = described_class.new([
        {"test_case" => "spec/models/old_spec.rb -- gone test", "reason" => "Legacy", "expires_on" => future_date}
      ])
      test_run = build_test_run([
        build_test_case(file: "spec/models/user_spec.rb", name: "User is valid", duration: 1.0)
      ])
      budget = build_budget(per_test_case: {default: 5})

      removed = allowlist.prune(test_run, budget)

      expect(removed.size).to eq(1)
      expect(removed.first.test_case_key).to eq("spec/models/old_spec.rb -- gone test")
      expect(allowlist.to_a).to be_empty
    end

    it "removes unnecessary entries and returns them" do
      allowlist = described_class.new([
        {"test_case" => "spec/models/user_spec.rb -- User is valid", "reason" => "Was slow", "expires_on" => future_date}
      ])
      test_run = build_test_run([
        build_test_case(file: "spec/models/user_spec.rb", name: "User is valid", duration: 1.0)
      ])
      budget = build_budget(per_test_case: {default: 5})

      removed = allowlist.prune(test_run, budget)

      expect(removed.size).to eq(1)
      expect(removed.first.test_case_key).to eq("spec/models/user_spec.rb -- User is valid")
      expect(allowlist.to_a).to be_empty
    end

    it "keeps active entries" do
      allowlist = described_class.new([
        {"test_case" => "spec/models/user_spec.rb -- User is valid", "reason" => "Known slow", "expires_on" => future_date}
      ])
      test_run = build_test_run([
        build_test_case(file: "spec/models/user_spec.rb", name: "User is valid", duration: 10.0)
      ])
      budget = build_budget(per_test_case: {default: 5})

      removed = allowlist.prune(test_run, budget)

      expect(removed).to be_empty
      expect(allowlist.to_a.size).to eq(1)
    end

    it "returns empty array when nothing to prune" do
      allowlist = described_class.new
      test_run = build_test_run([
        build_test_case(file: "spec/models/user_spec.rb", name: "User is valid", duration: 1.0)
      ])
      budget = build_budget(per_test_case: {default: 5})

      removed = allowlist.prune(test_run, budget)

      expect(removed).to eq([])
    end
  end

  describe "#to_a" do
    it "returns a copy of entries" do
      allowlist = described_class.new([
        {"test_case" => "spec/models/user_spec.rb -- User#slow", "reason" => "Legacy", "expires_on" => future_date}
      ])
      result = allowlist.to_a

      expect(result.size).to eq(1)
      expect(result.first).to be_a(TestBudget::Allowlist::Entry)
    end
  end
end
