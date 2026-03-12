# frozen_string_literal: true

RSpec.describe TestBudget::TestRun::Diff do
  describe "#to_s" do
    it "returns empty string when runs are identical" do
      test_cases = [
        build_test_case(file: "spec/models/user_spec.rb", duration: 2.0),
        build_test_case(file: "spec/system/login_spec.rb", duration: 50.0)
      ]

      before_run = TestBudget::TestRun.new(test_cases: test_cases, wall_time: 52.0)
      after_run = TestBudget::TestRun.new(test_cases: test_cases, wall_time: 52.0)

      output = described_class.new(before: before_run, after: after_run).to_s

      expect(output).to eq("")
    end

    it "shows delta for changed types sorted by absolute duration descending" do
      before_run = TestBudget::TestRun.new(
        test_cases: [
          build_test_case(file: "spec/models/user_spec.rb", duration: 10.0),
          build_test_case(file: "spec/system/login_spec.rb", duration: 50.0),
          build_test_case(file: "spec/requests/api_spec.rb", duration: 20.0)
        ],
        wall_time: 80.0
      )

      after_run = TestBudget::TestRun.new(
        test_cases: [
          build_test_case(file: "spec/models/user_spec.rb", duration: 5.0),
          build_test_case(file: "spec/system/login_spec.rb", duration: 30.0),
          build_test_case(file: "spec/requests/api_spec.rb", duration: 25.0)
        ],
        wall_time: 60.0
      )

      output = described_class.new(before: before_run, after: after_run).to_s

      lines = output.lines.map(&:rstrip)

      expect(lines[1]).to match(/Test Type\s+│\s+Δ Count\s+│\s+%\s+│\s+Δ Duration\s+│\s+%/)

      type_lines = lines[3..5]
      types_in_order = type_lines.map { |l| l.split("│")[1].strip }
      expect(types_in_order).to eq(%w[system model request])

      expect(output).to match(/system\s+│\s+0\s+│.*│\s+-20s\s+│\s+-40\.0%/)
      expect(output).to match(/model\s+│\s+0\s+│.*│\s+-5s\s+│\s+-50\.0%/)
      expect(output).to match(/request\s+│\s+0\s+│.*│\s+\+5s\s+│\s+\+25\.0%/)
    end

    it "shows 'new' in percent columns for new types" do
      before_run = TestBudget::TestRun.new(
        test_cases: [
          build_test_case(file: "spec/models/user_spec.rb", duration: 10.0)
        ],
        wall_time: 10.0
      )

      after_run = TestBudget::TestRun.new(
        test_cases: [
          build_test_case(file: "spec/models/user_spec.rb", duration: 10.0),
          build_test_case(file: "spec/system/login_spec.rb", duration: 30.0)
        ],
        wall_time: 40.0
      )

      output = described_class.new(before: before_run, after: after_run).to_s

      expect(output).to match(/system\s+│\s+\+1\s+│\s+new\s+│\s+\+30s\s+│\s+new/)
    end

    it "shows -100.0% for removed types" do
      before_run = TestBudget::TestRun.new(
        test_cases: [
          build_test_case(file: "spec/models/user_spec.rb", duration: 10.0),
          build_test_case(file: "spec/system/login_spec.rb", duration: 30.0)
        ],
        wall_time: 40.0
      )

      after_run = TestBudget::TestRun.new(
        test_cases: [
          build_test_case(file: "spec/models/user_spec.rb", duration: 10.0)
        ],
        wall_time: 10.0
      )

      output = described_class.new(before: before_run, after: after_run).to_s

      expect(output).to match(/system\s+│\s+-1\s+│\s+-100\.0%\s+│\s+-30s\s+│\s+-100\.0%/)
    end

    it "hides zero-delta rows" do
      before_run = TestBudget::TestRun.new(
        test_cases: [
          build_test_case(file: "spec/models/user_spec.rb", duration: 10.0),
          build_test_case(file: "spec/system/login_spec.rb", duration: 50.0)
        ],
        wall_time: 60.0
      )

      after_run = TestBudget::TestRun.new(
        test_cases: [
          build_test_case(file: "spec/models/user_spec.rb", duration: 10.0),
          build_test_case(file: "spec/system/login_spec.rb", duration: 30.0)
        ],
        wall_time: 40.0
      )

      output = described_class.new(before: before_run, after: after_run).to_s

      expect(output).to include("system")
      expect(output).not_to include("model")
    end

    it "shows correct total footer" do
      before_run = TestBudget::TestRun.new(
        test_cases: [
          build_test_case(file: "spec/models/user_spec.rb", duration: 10.0),
          build_test_case(file: "spec/system/login_spec.rb", duration: 50.0)
        ],
        wall_time: 60.0
      )

      after_run = TestBudget::TestRun.new(
        test_cases: [
          build_test_case(file: "spec/models/user_spec.rb", duration: 5.0),
          build_test_case(file: "spec/system/login_spec.rb", duration: 30.0),
          build_test_case(file: "spec/requests/api_spec.rb", duration: 10.0)
        ],
        wall_time: 45.0
      )

      output = described_class.new(before: before_run, after: after_run).to_s

      expect(output).to match(/Total\s+│\s+\+1\s+│\s+\+50\.0%\s+│\s+-15s\s+│\s+-25\.0%/)
    end

    it "formats durations with minutes and signs" do
      before_run = TestBudget::TestRun.new(
        test_cases: [
          build_test_case(file: "spec/system/login_spec.rb", duration: 10.0)
        ],
        wall_time: 10.0
      )

      after_run = TestBudget::TestRun.new(
        test_cases: [
          build_test_case(file: "spec/system/login_spec.rb", duration: 512.0)
        ],
        wall_time: 512.0
      )

      output = described_class.new(before: before_run, after: after_run).to_s

      expect(output).to match(/\+8m 22s/)
    end
  end
end
