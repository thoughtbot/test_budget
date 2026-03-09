# frozen_string_literal: true

RSpec.describe TestBudget::Violation do
  describe "#message" do
    it "formats per_test_case violation message" do
      test_case = TestBudget::TestCase.new(
        file: "spec/models/user_spec.rb", name: "User#full_name",
        duration: 2.5, status: "passed", line_number: 4
      )
      violation = described_class.new(test_case: test_case, duration: 2.5, limit: 2.0, kind: :per_test_case)

      expect(violation.message).to eq("spec/models/user_spec.rb -- User#full_name (2.50s) exceeds model limit (2.00s)")
    end

    it "formats per_test_case violation message with inferred type" do
      test_case = TestBudget::TestCase.new(
        file: "spec/lib/utils_spec.rb", name: "Utils.parse",
        duration: 6.0, status: "passed", line_number: 4
      )
      violation = described_class.new(test_case: test_case, duration: 6.0, limit: 5.0, kind: :per_test_case)

      expect(violation.message).to eq("spec/lib/utils_spec.rb -- Utils.parse (6.00s) exceeds lib limit (5.00s)")
    end

    it "handles % in test name" do
      test_case = TestBudget::TestCase.new(
        file: "spec/models/user_spec.rb", name: "handles 100% of cases",
        duration: 2.5, status: "passed", line_number: 4
      )
      violation = described_class.new(test_case: test_case, duration: 2.5, limit: 2.0, kind: :per_test_case)

      expect(violation.message).to eq("spec/models/user_spec.rb -- handles 100% of cases (2.50s) exceeds model limit (2.00s)")
    end

    it "formats suite violation message" do
      violation = described_class.new(test_case: nil, duration: 650.0, limit: 600.0, kind: :suite)

      expect(violation.message).to eq("Suite total time (650.00s) exceeds limit (600.00s)")
    end
  end

  describe "#locator" do
    it "returns locator for per_test_case violations" do
      test_case = TestBudget::TestCase.new(
        file: "spec/models/user_spec.rb", name: "User#full_name",
        duration: 2.5, status: "passed", line_number: 4
      )
      violation = described_class.new(
        test_case: test_case, duration: 2.5,
        limit: 2.0, kind: :per_test_case
      )

      expect(violation.locator).to eq("spec/models/user_spec.rb:4")
    end

    it "returns nil for suite violations" do
      violation = described_class.new(test_case: nil, duration: 650.0, limit: 600.0, kind: :suite)

      expect(violation.locator).to be_nil
    end
  end
end
