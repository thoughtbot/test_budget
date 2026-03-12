# frozen_string_literal: true

require "optparse"
require "argument_parser"

module TestBudget
  class CLI
    def call(argv)
      args = argv.dup

      return print_help if args.empty? || (args & %w[--help -h]).any?
      return print_version if (args & %w[--version -v]).any?

      parsed = command_parser.parse!(args)

      case parsed[:command]
      in "audit" then run_audit(args)
      in "allowlist" then run_allowlist(args)
      in "prune" then run_prune(args)
      in "init" | "estimate" then run_init(args)
      in "breakdown" then run_breakdown(args)
      in "help" then print_help
      end
    rescue ArgumentParser::ParseError, TestBudget::Error, OptionParser::MissingArgument, OptionParser::InvalidArgument => e
      warn e.message
      1
    end

    private

    def command_parser
      ArgumentParser.build do
        required :command, pattern: ["audit", "allowlist", "prune", "init", "estimate", "breakdown", "help"]
      end
    end

    def print_help
      puts help_text
      0
    end

    def print_version
      puts "test_budget #{TestBudget::VERSION}"
      0
    end

    def help_text
      <<~HELP
        Usage: test_budget <command> [options]

        Commands:
          audit       Check test results against budget
          allowlist   Exclude a test from budget checks
          prune       Remove obsolete allowlist entries
          init        Generate starter .test_budget.yml config
          estimate    Alias for init
          breakdown   Show time distribution across test types
          help        Show this help message

        Options:
          -h, --help     Show this help message
          -v, --version  Show version
      HELP
    end

    def run_audit(args)
      budget_path = DEFAULT_BUDGET_PATH
      tolerant = false

      OptionParser.new do |opts|
        opts.banner = "Usage: test_budget audit [options]"
        opts.on("--budget PATH", "Path to budget file") { |path| budget_path = path }
        opts.on("--tolerant", "Apply 10% tolerance to limits") { tolerant = true }
      end.parse!(args)

      result = Audit.new(budget_path: budget_path, tolerant: tolerant).perform

      result.passed? ? 0 : 1
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
      puts "Allowlisted: #{entry.test_case_key}"

      0
    end

    def run_prune(args)
      budget_path = DEFAULT_BUDGET_PATH

      OptionParser.new do |opts|
        opts.banner = "Usage: test_budget prune [options]"
        opts.on("--budget PATH", "Path to budget file") { |path| budget_path = path }
      end.parse!(args)

      removed = Budget.load(budget_path).prune_allowlist

      if removed.any?
        puts "#{removed.size} obsolete allowlist #{Inflector.pluralize("entry", removed.size)} removed"
      else
        puts "No obsolete allowlist entries found"
      end

      0
    end

    def run_breakdown(args)
      sort = :duration

      OptionParser.new do |opts|
        opts.banner = "Usage: test_budget breakdown [timings_file] [options]"
        opts.on("--sort FIELD", TestRun::Breakdown::SORT_OPTIONS, "Sort by: duration (default), count, type") { |s| sort = s }
      end.parse!(args)

      timings_path = args.shift || DEFAULT_TIMINGS_PATH
      test_run = Parser::Rspec.parse(timings_path)
      puts TestRun::Breakdown.new(test_run: test_run, sort: sort)
      0
    end

    def run_init(args)
      force = false

      OptionParser.new do |opts|
        opts.banner = "Usage: test_budget init [timings_file] [options]"
        opts.on("--force", "Overwrite existing config") { force = true }
      end.parse!(args)
      timings_path = args.shift

      Budget.estimate(timings_path: timings_path, force: force)

      0
    end
  end
end
