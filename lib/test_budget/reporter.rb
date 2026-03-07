# frozen_string_literal: true

module TestBudget
  class Reporter
    def initialize(output:, budget_path:)
      @output = output
      @budget_path = budget_path
    end

    def report(violations)
      if violations.empty?
        @output.puts "Test budget: all clear"
        return
      end

      @output.puts "Test budget: #{violations.size} violation(s) found\n\n"

      violations.each_with_index do |violation, index|
        @output.puts "  #{index + 1}) #{violation.message}"

        if (locator = violation.locator)
          budget_flag = (@budget_path == ".test_budget.yml") ? "" : " --budget #{@budget_path}"
          @output.puts "     To allowlist, run:"
          @output.puts "     bundle exec test_budget allowlist #{locator}#{budget_flag} --reason \"<reason>\""
        end
      end
    end
  end
end
