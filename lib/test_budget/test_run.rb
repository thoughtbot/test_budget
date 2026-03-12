# frozen_string_literal: true

module TestBudget
  class TestRun < Data.define(:test_cases, :suite_duration)
    Group = Data.define(:type, :count, :duration, :test_run) do
      def percent_count = count * 100.0 / test_run.size

      def percent_duration = duration * 100.0 / test_run.total_duration
    end

    def size = test_cases.size
    def total_duration = test_cases.sum(&:duration)

    def over?(budget)
      max = budget.suite.max_duration
      return if max.nil?
      return if suite_duration <= max

      Violation.new(test_case: nil, duration: suite_duration, limit: max, kind: :suite)
    end

    def groups
      test_cases
        .group_by(&:type)
        .map { |type, cases|
          Group.new(type: type, count: cases.size, duration: cases.sum(&:duration), test_run: self)
        }
        .sort_by { |g| -g.duration }
    end
  end
end
