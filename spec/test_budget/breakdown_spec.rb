# frozen_string_literal: true

RSpec.describe TestBudget::Breakdown do
  describe "#to_s" do
    it "groups test cases by type and sorts by duration descending" do
      test_run = TestBudget::TestRun.new(
        test_cases: [
          build_test_case(file: "spec/models/user_spec.rb", duration: 2.0),
          build_test_case(file: "spec/models/post_spec.rb", duration: 3.0),
          build_test_case(file: "spec/system/login_spec.rb", duration: 50.0),
          build_test_case(file: "spec/requests/api_spec.rb", duration: 10.0)
        ],
        wall_time: 65.0
      )

      output = described_class.new(test_run).to_s

      lines = output.lines.map(&:rstrip)

      expect(lines[0]).to match(/Test Type\s+Count\s+%\s+Duration\s+%/)

      type_lines = lines[2..4]
      types_in_order = type_lines.map { |l| l.strip.split(/\s+/).first }
      expect(types_in_order).to eq(%w[system request model])
    end

    it "calculates correct percentages" do
      test_run = TestBudget::TestRun.new(
        test_cases: [
          build_test_case(file: "spec/models/user_spec.rb", duration: 25.0),
          build_test_case(file: "spec/system/login_spec.rb", duration: 75.0)
        ],
        wall_time: 100.0
      )

      output = described_class.new(test_run).to_s

      expect(output).to match(/system\s+1\s+50\.0%\s+1m 15s\s+75\.0%/)
      expect(output).to match(/model\s+1\s+50\.0%\s+25s\s+25\.0%/)
    end

    it "formats durations in human-readable format" do
      test_run = TestBudget::TestRun.new(
        test_cases: [
          build_test_case(file: "spec/models/user_spec.rb", duration: 256.5)
        ],
        wall_time: 256.5
      )

      output = described_class.new(test_run).to_s

      expect(output).to include("4m 17s")
    end

    it "shows totals row" do
      test_run = TestBudget::TestRun.new(
        test_cases: [
          build_test_case(file: "spec/models/user_spec.rb", duration: 10.0),
          build_test_case(file: "spec/system/login_spec.rb", duration: 50.0)
        ],
        wall_time: 60.0
      )

      output = described_class.new(test_run).to_s

      expect(output).to match(/Total\s+2\s+1m 0s/)
    end

    it "returns a message when there are no test cases" do
      test_run = TestBudget::TestRun.new(test_cases: [], wall_time: 0)

      output = described_class.new(test_run).to_s

      expect(output).to include("No test cases found")
    end

    it "handles irregular type names" do
      test_run = TestBudget::TestRun.new(
        test_cases: [
          build_test_case(file: "spec/policies/admin_policy_spec.rb", duration: 5.0),
          build_test_case(file: "spec/factories/user_factory_spec.rb", duration: 3.0)
        ],
        wall_time: 8.0
      )

      output = described_class.new(test_run).to_s

      expect(output).to match(/policy/)
      expect(output).to match(/factory/)
    end
  end
end
