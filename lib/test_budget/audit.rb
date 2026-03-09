# frozen_string_literal: true

module TestBudget
  class Audit
    Result = Data.define(:violations, :warnings) do
      def passed? = violations.empty?
    end

    def initialize(budget_path:, tolerant: false)
      @budget_path = budget_path
      @tolerant = tolerant
    end

    def perform
      budget = Budget.load(@budget_path)
      test_run = Parser::Rspec.parse(budget.timings_path)
      result = Auditor.new(budget, tolerant: @tolerant).audit(test_run)
      Reporter.new(budget_path: @budget_path).report(result)

      result
    end
  end
end
