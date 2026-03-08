# frozen_string_literal: true

module TestBudget
  module Checks
    class Suite
      def initialize(budget)
        @budget = budget
      end

      def check(suite_duration)
        max = @budget.suite.max_duration
        return if max.nil?
        return if suite_duration <= max

        Violation.new(test_case: nil, duration: suite_duration, limit: max, kind: :suite)
      end
    end
  end
end
