# frozen_string_literal: true

module TestBudget
  module Checks
    class PerTestCase
      def initialize(budget)
        @budget = budget
      end

      def check(test_case)
        limit = @budget.per_test_case.types[test_case.type] || @budget.per_test_case.default

        return unless limit
        return if test_case.duration <= limit

        Violation.new(test_case: test_case, duration: test_case.duration, limit: limit, kind: :per_test_case)
      end
    end
  end
end
