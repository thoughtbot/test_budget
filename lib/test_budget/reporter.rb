# frozen_string_literal: true

module TestBudget
  class Reporter
    def initialize(output:)
      @output = output
    end

    def report(violations)
      if violations.empty?
        @output.puts "Test budget: all clear"
        return
      end

      @output.puts "Test budget: #{violations.size} violation(s) found\n\n"

      violations.each_with_index do |violation, index|
        @output.puts "  #{index + 1}) #{violation.message}"

        if (snippet = violation.allowlist_snippet)
          @output.puts "     To allowlist, add to .test_budget.yml:"
          @output.puts "     #{snippet}"
        end

        @output.puts
      end
    end
  end
end
