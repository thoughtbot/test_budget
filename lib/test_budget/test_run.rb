# frozen_string_literal: true

module TestBudget
  class TestRun < Data.define(:test_cases, :suite_duration)
    def over?(budget)
      max = budget.suite.max_duration
      return if max.nil?
      return if suite_duration <= max

      Violation.new(test_case: nil, duration: suite_duration, limit: max, kind: :suite)
    end
  end
end
