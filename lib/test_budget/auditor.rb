# frozen_string_literal: true

module TestBudget
  class Auditor
    def initialize(budget)
      @budget = budget
      @per_test_case = Checks::PerTestCase.new(budget)
      @suite = Checks::Suite.new(budget)
    end

    def audit(test_cases)
      [
        test_case_violations(test_cases),
        suite_violation(test_cases)
      ].flatten.compact
    end

    private

    def test_case_violations(test_cases)
      test_cases.filter_map do |test_case|
        next if @budget.allowed?(test_case)

        @per_test_case.check(test_case)
      end
    end

    def suite_violation(test_cases) = @suite.check(test_cases)
  end
end
