# frozen_string_literal: true

RSpec.describe TestBudget::TestRun do
  describe "#over?" do
    it "returns nil when under budget" do
      budget = build_budget(suite: {max_duration: 600})
      test_run = described_class.new(test_cases: [], wall_time: 500)

      expect(test_run.over?(budget)).to be_nil
    end

    it "returns violation when over budget" do
      budget = build_budget(suite: {max_duration: 600})
      test_run = described_class.new(test_cases: [], wall_time: 700)

      result = test_run.over?(budget)

      expect(result).to be_a(TestBudget::Violation)
      expect(result.kind).to eq(:suite)
      expect(result.duration).to eq(700)
      expect(result.limit).to eq(600)
    end

    it "returns nil when max_duration is nil" do
      budget = build_budget
      test_run = described_class.new(test_cases: [], wall_time: 9999)

      expect(test_run.over?(budget)).to be_nil
    end

    it "returns nil when duration is zero" do
      budget = build_budget(suite: {max_duration: 600})
      test_run = described_class.new(test_cases: [], wall_time: 0)

      expect(test_run.over?(budget)).to be_nil
    end
  end

  describe "#size" do
    it "returns the number of test cases" do
      test_run = described_class.new(
        test_cases: [
          build_test_case(file: "spec/models/user_spec.rb", duration: 1.0),
          build_test_case(file: "spec/models/post_spec.rb", duration: 2.0)
        ],
        wall_time: 3.0
      )

      expect(test_run.size).to eq(2)
    end
  end

  describe "#total_time" do
    it "returns the sum of all test case durations" do
      test_run = described_class.new(
        test_cases: [
          build_test_case(file: "spec/models/user_spec.rb", duration: 1.5),
          build_test_case(file: "spec/models/post_spec.rb", duration: 2.5)
        ],
        wall_time: 4.0
      )

      expect(test_run.total_time).to eq(4.0)
    end
  end

  describe "#groups" do
    it "groups test cases by type sorted by duration descending with percentages" do
      test_run = described_class.new(
        test_cases: [
          build_test_case(file: "spec/models/user_spec.rb", duration: 2.0),
          build_test_case(file: "spec/models/post_spec.rb", duration: 3.0),
          build_test_case(file: "spec/system/login_spec.rb", duration: 50.0)
        ],
        wall_time: 55.0
      )

      groups = test_run.groups

      expect(groups.map(&:type)).to eq([:system, :model])

      system_group = groups[0]
      expect(system_group).to have_attributes(count: 1, duration: 50.0)
      expect(system_group.percent_count).to be_within(0.1).of(33.3)
      expect(system_group.percent_duration).to be_within(0.1).of(90.9)

      model_group = groups[1]
      expect(model_group).to have_attributes(count: 2, duration: 5.0)
      expect(model_group.percent_count).to be_within(0.1).of(66.7)
      expect(model_group.percent_duration).to be_within(0.1).of(9.1)
    end

    it "returns empty array when no test cases" do
      test_run = described_class.new(test_cases: [], wall_time: 0)

      expect(test_run.groups).to eq([])
    end
  end

  describe TestBudget::TestRun::Group do
    it "derives percentages from its test run" do
      test_run = TestBudget::TestRun.new(
        test_cases: [
          build_test_case(file: "spec/models/user_spec.rb", duration: 25.0),
          build_test_case(file: "spec/models/post_spec.rb", duration: 75.0)
        ],
        wall_time: 100.0
      )

      group = described_class.new(type: :model, count: 1, duration: 25.0, test_run: test_run)

      expect(group.percent_count).to eq(50.0)
      expect(group.percent_duration).to eq(25.0)
    end
  end
end
