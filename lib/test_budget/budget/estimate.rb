# frozen_string_literal: true

require "yaml"

module TestBudget
  class Budget
    class Estimate
      DEFAULT_RESULTS_PATH = "tmp/test_budget_results.json"
      BUFFER = 0.10
      PER_TEST_CASE_DEFAULTS = {"default" => 3, "system" => 6, "request" => 3, "model" => 1.5}.freeze

      def initialize(output:, results_path: nil, force: false)
        @results_path = results_path
        @output = output
        @force = force
      end

      def generate
        guard_existing_config!

        if @results_path
          generate_from_results
        else
          generate_defaults
        end

        @output.puts "Created #{DEFAULT_BUDGET_PATH}"
      end

      private

      def guard_existing_config!
        return if @force || !File.exist?(DEFAULT_BUDGET_PATH)

        raise TestBudget::Error, "#{DEFAULT_BUDGET_PATH} already exists. Use --force to overwrite."
      end

      def generate_from_results
        test_cases = Parser::Rspec.parse(@results_path)
        timed_cases = test_cases.filter(&:duration)
        suite_duration = timed_cases.sum(&:duration)
        suite_budget = (suite_duration * (1 + BUFFER)).ceil
        per_test_case_limits = derive_per_test_case(timed_cases)

        budget = build_budget(
          results_path: @results_path,
          suite_max_duration: suite_budget,
          per_test_case_limits: per_test_case_limits
        )
        budget.save
      end

      def generate_defaults
        build_budget(
          results_path: DEFAULT_RESULTS_PATH,
          per_test_case_limits: PER_TEST_CASE_DEFAULTS
        ).save
      end

      def build_budget(results_path:, per_test_case_limits:, suite_max_duration: nil)
        types = per_test_case_limits.except("default").transform_keys(&:to_sym)

        Budget.new(
          path: DEFAULT_BUDGET_PATH,
          results_path: results_path,
          suite: Budget::Suite.new(max_duration: suite_max_duration),
          per_test_case: Budget::PerTestCase.new(
            default: per_test_case_limits["default"],
            types: types
          ),
          allowlist: Allowlist.new
        )
      end

      def derive_per_test_case(test_cases)
        grouped = test_cases.group_by { |tc| tc.type.to_s }

        PER_TEST_CASE_DEFAULTS.merge(
          grouped.transform_values { |cases|
            Statistics.percentile_95(cases.map(&:duration), buffer: BUFFER)
          }
        )
      end
    end
  end
end
