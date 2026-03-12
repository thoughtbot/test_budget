# frozen_string_literal: true

module TestBudget
  class TestRun < Data.define(:test_cases, :wall_time)
    Group = Data.define(:type, :count, :duration, :test_run) do
      def percent_count = count * 100.0 / test_run.size

      def percent_duration = duration * 100.0 / test_run.total_time
    end

    def size = test_cases.size
    def total_time = test_cases.sum(&:duration)

    alias_method :count, :size
    alias_method :duration, :total_time

    def over?(budget)
      max = budget.suite.max_duration
      return if max.nil?
      return if wall_time <= max

      Violation.new(test_case: nil, duration: wall_time, limit: max, kind: :suite)
    end

    def groups
      test_cases
        .group_by(&:type)
        .map { |type, cases|
          Group.new(type: type, count: cases.size, duration: cases.sum(&:duration), test_run: self)
        }
    end
  end
end
