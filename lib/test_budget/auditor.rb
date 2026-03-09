# frozen_string_literal: true

module TestBudget
  class Auditor
    TOLERANCE = 0.1

    def initialize(budget, tolerant: false)
      @budget = tolerant ? budget.inflate_by(TOLERANCE) : budget
    end

    def audit(test_run)
      Audit::Result.new(
        violations: violations_for(test_run),
        warnings: warnings_for(test_run)
      )
    end

    private

    def violations_for(test_run)
      violations = test_run.test_cases.filter_map { |tc| tc.violation_for(@budget) }
      violations << test_run.over?(@budget)
      violations.compact
    end

    def warnings_for(test_run)
      @budget.allowlist.to_a.filter_map do |entry|
        kind = entry.obsolete?(test_run, @budget)
        Warning.new(entry: entry, kind: kind) if kind
      end
    end
  end
end
