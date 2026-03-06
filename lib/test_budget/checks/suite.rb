# frozen_string_literal: true

module TestBudget
  module Checks
    class Suite
      def initialize(budget)
        @budget = budget
      end

      def check(test_cases)
        max = @budget.suite.max_duration
        return if max.nil?

        total = test_cases.sum(&:duration)
        return if total <= max

        Violation.new(test_case: nil, duration: total, limit: max, kind: :suite)
      end
    end
  end
end
