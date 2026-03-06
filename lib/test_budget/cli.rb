# frozen_string_literal: true

require "optparse"

module TestBudget
  class CLI
    def initialize(output: $stdout, error: $stderr)
      @output = output
      @error = error
    end

    def call(argv)
      budget_path = DEFAULT_BUDGET_PATH
      args = argv.dup

      OptionParser.new do |opts|
        opts.banner = "Usage: test_budget [audit] [options]"
        opts.on("--budget PATH", "Path to budget file") { |path| budget_path = path }
      end.parse!(args)

      passed = Audit.new(budget_path: budget_path, output: @output).perform
      passed ? 0 : 1
    rescue TestBudget::Error => e
      @error.puts e.message
      1
    end
  end
end
