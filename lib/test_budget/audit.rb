# frozen_string_literal: true

module TestBudget
  class Audit
    def initialize(budget_path:, output:)
      @budget_path = budget_path
      @output = output
    end

    def perform
      budget = Budget.load(@budget_path)
      test_cases = Parser::Rspec.parse(budget.results_path)
      violations = Auditor.new(budget).audit(test_cases)
      Reporter.new(output: @output).report(violations)

      violations.empty?
    end
  end
end
