# frozen_string_literal: true

module TestBudget
  class Audit
    def initialize(budget_path:, output:)
      @budget_path = budget_path
      @output = output
    end

    def perform
      budget = Budget.load(@budget_path)
      test_run = Parser::Rspec.parse(budget.timings_path)
      violations = Auditor.new(budget).audit(test_run)
      Reporter.new(output: @output, budget_path: @budget_path).report(violations)

      violations.empty?
    end
  end
end
