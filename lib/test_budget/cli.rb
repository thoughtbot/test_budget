# frozen_string_literal: true

require "optparse"
require "argument_parser"

module TestBudget
  class CLI
    def initialize(output: $stdout, error: $stderr)
      @output = output
      @error = error
    end

    def call(argv)
      args = argv.dup
      parsed = command_parser.parse!(args)

      case parsed[:command]
      in "audit" then run_audit(args)
      in "allowlist" then run_allowlist(args)
      in "init" then run_init(args)
      end
    rescue ArgumentParser::ParseError, TestBudget::Error, OptionParser::MissingArgument => e
      @error.puts e.message
      1
    end

    private

    def command_parser
      ArgumentParser.build do
        required :command, pattern: %w[audit allowlist init]
      end
    end

    def run_audit(args)
      budget_path = DEFAULT_BUDGET_PATH

      OptionParser.new do |opts|
        opts.banner = "Usage: test_budget audit [options]"
        opts.on("--budget PATH", "Path to budget file") { |path| budget_path = path }
      end.parse!(args)

      passed = Audit.new(budget_path: budget_path, output: @output).perform

      passed ? 0 : 1
    end

    def run_allowlist(args)
      budget_path = DEFAULT_BUDGET_PATH
      reason = nil

      OptionParser.new do |opts|
        opts.banner = "Usage: test_budget allowlist FILE:LINE --reason REASON [options]"
        opts.on("--budget PATH", "Path to budget file") { |path| budget_path = path }
        opts.on("--reason REASON", "Reason for allowlisting") { |r| reason = r }
      end.parse!(args)

      locator = args.shift
      raise Error, "--reason is required for allowlist" unless reason
      raise Error, "locator (e.g., spec/file_spec.rb:10) is required" unless locator

      entry = Budget.load(budget_path).add_to_allowlist(locator, reason: reason)
      @output.puts "Allowlisted: #{entry.test_case_key}"

      0
    end

    def run_init(args)
      force = false

      OptionParser.new do |opts|
        opts.banner = "Usage: test_budget init [results_file] [options]"
        opts.on("--force", "Overwrite existing config") { force = true }
      end.parse!(args)
      results_path = args.shift

      Onboarding.new(results_path: results_path, output: @output, force: force).start

      0
    end
  end
end
