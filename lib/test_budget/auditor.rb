# frozen_string_literal: true

module TestBudget
  class Auditor
    def initialize(budget)
      @budget = budget
    end

    def audit(test_run)
      violations = test_run.test_cases.filter_map { |it| it.violation_for(@budget) }
      violations << test_run.over?(@budget)
      violations.compact
    end
  end
end
